# frozen_string_literal: true

require "test_helper"

# P1.55B §10 — 소스 장애 알림.
#
# 이 파일의 규율(§33 zero-claim gate):
#   "3회에서 알림 1건" 이라는 **양성 대조를 먼저 통과시킨 뒤에만** "1·2회에서 0건" 을 주장한다.
#   같은 테스트 안에서 0 → 0 → 1 궤적을 함께 단언하므로, 검출기가 죽어 있으면 이 테스트가 깨진다.
#
# 실패 주입 방법: fetch_strategy="manual" 은 ChangeDetector 가 지원하지 않아
#                외부 네트워크 없이 결정적으로 PARSE_FAILED 를 만든다.
class Authority::SourceFailureAlertTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  class MailServerDown < StandardError; end

  # 메일 서버 장애를 배달 계층에서 재현한다(몽키패치 없이).
  # 메일러 렌더링까지 실제로 수행한 뒤 발송에서 실패하므로 운영 장애에 가깝다.
  class FailingDelivery
    def initialize(settings = {}) = @settings = settings
    def deliver!(_mail) = raise(MailServerDown, "메일 서버 다운")
  end

  ActionMailer::Base.add_delivery_method :failing_for_test, FailingDelivery

  setup do
    @source = create_source(fetch_strategy: "manual", name: "테스트 법령 출처")
    @document = create_document(source: @source)
    ActionMailer::Base.deliveries.clear
  end

  # 한 번 실행 = 실패 1회
  def run_check = AuthorityFreshnessCheckJob.new.perform(document_ids: [ @document.id ])

  def alert_count = ActionMailer::Base.deliveries.size

  # ---------------------------------------------------------------- 임계값

  test "임계값 궤적 — 1회 0건 · 2회 0건 · 3회 1건 (양성 대조 포함)" do
    run_check
    assert_equal 1, @source.reload.failure_count
    assert_equal 0, alert_count, "1회 실패에서 알림이 나갔다"

    run_check
    assert_equal 2, @source.reload.failure_count
    assert_equal 0, alert_count, "2회 실패에서 알림이 나갔다"

    report = run_check
    assert_equal 3, @source.reload.failure_count
    # 양성 대조: 여기서 1건이 나오지 않으면 위의 0건은 아무것도 증명하지 못한다.
    assert_equal 1, alert_count, "3회 연속 실패인데 운영자 알림이 발송되지 않았다"
    assert_equal 1, report[:alerts_sent]
    assert_not_nil @source.reload.alerted_at
  end

  test "같은 episode 의 4회째 실패는 추가 알림을 보내지 않는다" do
    3.times { run_check }
    assert_equal 1, alert_count, "양성 대조 실패 — 3회에서 알림이 없다"

    report = run_check
    assert_equal 4, @source.reload.failure_count
    assert_equal 1, alert_count, "같은 장애로 알림이 중복 발송됐다"
    assert_equal 0, report[:alerts_sent]
  end

  test "복구하면 장애 episode 가 닫히고 다음 장애에서 다시 알린다" do
    3.times { run_check }
    assert_equal 1, alert_count

    @source.reload.record_success!
    assert_equal 0, @source.failure_count
    assert_nil @source.first_failed_at, "복구했는데 장애 시작 시각이 남아 있다"
    assert_nil @source.alerted_at, "복구했는데 알림 이력이 초기화되지 않았다"

    3.times { run_check }
    assert_equal 2, alert_count, "새 장애 episode 에서 다시 알리지 않았다"
    assert_not_nil @source.reload.alerted_at
  end

  test "degraded(5회 이상)로 건너뛰는 소스도 아직 안 알렸으면 알린다" do
    @source.update_columns(failure_count: AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES,
                           alerted_at: nil)

    report = run_check
    assert_equal 1, report[:skipped_failing]
    assert_equal 0, report[:checked]
    assert_equal 1, alert_count, "degraded 소스가 조용히 건너뛰어졌다 — 사람이 알 경로가 없다"
  end

  # ---------------------------------------------------------------- first_failed_at

  test "first_failed_at 은 episode 최초 실패에만 찍히고 이후 실패로 옮겨지지 않는다" do
    run_check
    first = @source.reload.first_failed_at
    assert_not_nil first

    travel 1.hour do
      run_check
    end
    assert_equal first.to_i, @source.reload.first_failed_at.to_i,
                 "후속 실패가 장애 시작 시각을 덮어썼다"
    assert_equal 2, @source.failure_count
  end

  # ------------------------------------------------- §29·§34 알림 실패 격리

  test "알림 전송이 실패해도 수집 결과는 유지된다" do
    2.times { run_check }
    ActionMailer::Base.deliveries.clear

    report = with_failing_mail_delivery { run_check }

    # 수집 자체는 정상 종료했고 실패도 정상 계수됐다
    assert_equal 1, report[:checked], "알림 실패가 수집을 중단시켰다"
    assert_equal 1, report[:failed]
    assert_equal 0, report[:alerts_sent]
    assert_equal 3, @source.reload.failure_count, "알림 실패로 수집 상태가 기록되지 않았다"
    assert_equal 0, alert_count
  end

  test "알림 전송에 실패하면 alerted_at 을 찍지 않아 다음 주기에 다시 시도한다" do
    2.times { run_check }
    with_failing_mail_delivery { run_check }
    assert_nil @source.reload.alerted_at, "발송에 실패했는데 알림 완료로 기록됐다"

    ActionMailer::Base.deliveries.clear
    run_check
    assert_equal 1, alert_count, "복구된 메일 경로에서 재시도되지 않았다"
    assert_not_nil @source.reload.alerted_at
  end

  # ---------------------------------------------------------------- 메일 내용

  test "알림 메일은 ADMIN_EMAIL 로 가고 소스 상태를 담는다" do
    3.times { run_check }
    mail = ActionMailer::Base.deliveries.last

    assert_equal [ ENV["ADMIN_EMAIL"] || "hello@silmu.kr" ], mail.to
    assert_includes mail.subject, "테스트 법령 출처"
    assert_includes mail.subject, "3회"
    body = mail.body.to_s
    assert_includes body, @source.key
    assert_includes body, "PARSE_FAILED"
    assert_includes body, "콘텐츠는 변경되지 않았습니다"
  end

  # -------------------------------------------------------- 콘텐츠 무변경

  test "알림 경로가 열려도 게시 콘텐츠 본문은 바뀌지 않는다 (§39)" do
    before = content_body_snapshot
    refute_empty before["Topic"], "스냅샷이 비어 있으면 '무변경' 은 아무것도 증명하지 못한다"

    # 양성 대조 1 — 탐지기가 실제로 본문 변경을 잡는가.
    # 이것이 통과하지 않으면 아래의 "본문 무변경" 주장은 무의미하다.
    probe = Topic.order(:id).first
    original = probe.summary
    probe.update_columns(summary: "#{original}·MUTATION_PROBE")
    assert_not_equal before, content_body_snapshot,
                     "탐지기가 본문 변경을 못 잡는다 — 무변경 주장이 성립하지 않는다"
    probe.update_columns(summary: original)
    assert_equal before, content_body_snapshot, "양성 대조 복원 실패"

    # 양성 대조 2 — 알림 경로가 실제로 실행됐는가
    3.times { run_check }
    assert_equal 1, alert_count, "알림 경로가 실행되지 않았다"

    assert_equal before, content_body_snapshot, "알림 경로 실행이 게시 본문을 바꿨다"
  end

  private

  def with_failing_mail_delivery
    previous = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :failing_for_test
    yield
  ensure
    ActionMailer::Base.delivery_method = previous
  end

  def content_body_snapshot
    {
      "Topic" => Topic.order(:id).pluck(:id, :law_content, :decree_content, :rule_content, :commentary, :summary),
      "Guide" => Guide.order(:id).pluck(:id, :summary, :sections),
      "AuditCase" => AuditCase.order(:id).pluck(:id, :issue, :detail, :lesson, :action_taken, :legal_basis)
    }
  end
end
