# frozen_string_literal: true

require "test_helper"

# P2 R1 / P-1 — "조용한 FAQ 소실"의 정체를 테스트로 고정한다.
#
# ⚠️ 픽스처를 **추가하지 않는다**. test/fixtures/topics.yml 상단 경고 참조 —
#    토픽을 하나만 더해도 home_controller_test 의 skip 이 풀려 다른 테스트가 깨진다.
#    그래서 기존 픽스처 토픽의 컬럼을 트랜잭션 안에서 직접 바꿔 쓴다.
class TopicFaqIntegrityTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:local_private_contract)
  end

  # ── 현재 동작 고정: 깨진 payload 는 예외가 아니라 침묵으로 사라진다 ──
  # 이 침묵이 운영에서 공개 토픽 2건의 FAQ 9건을 몇 달간 감췄다(2026-09-06 실측).
  # 동작 자체는 방어적이라 유지하되, **그 사실을 테스트로 눈에 보이게 못 박는다.**
  test "faq_list 는 깨진 payload 에 대해 예외 대신 빈 배열을 준다 — 소실이 조용한 이유" do
    @topic.update_column(:faqs, '[{"answer"=>"a", "question"=>"q"}]')
    @topic.reload

    assert_equal [], @topic.faq_list, "rescue 가 [] 를 돌려주므로 화면은 안 죽지만 FAQ 도 안 보인다"
    assert_equal 1, FaqPayloadNormalizer.authored_count(@topic.faqs),
                 "저작된 FAQ 는 1건인데 도달 가능한 건수는 0 — 이 격차가 FAQ_LOST 다"
  end

  # ── 양성대조: 검사기가 깨진 것을 실제로 잡는가 ──
  test "classify 가 심어둔 STRING_BROKEN 을 검출한다" do
    @topic.update_column(:faqs, '[{"answer"=>"a", "question"=>"q"}]')
    @topic.reload

    assert_equal :string_broken, FaqPayloadNormalizer.classify(@topic.faqs)
  end

  test "classify 가 심어둔 이중 인코딩(STRING_PARSEABLE)을 검출한다" do
    @topic.update_column(:faqs, '[{"question":"q","answer":"a"}]')
    @topic.reload

    assert_equal :string_parseable, FaqPayloadNormalizer.classify(@topic.faqs)
    assert_equal 1, @topic.faq_list.size, "이 형태는 faq_list 가 구제하므로 도달은 된다"
  end

  # ── 음성대조: 정상 토픽을 결함으로 잡지 않는가 ──
  # 양성만 보면 "전부 결함"이라고 답하는 검사기도 통과한다.
  test "정상 배열 토픽은 결함으로 잡히지 않는다" do
    @topic.update_column(:faqs, [ { "question" => "q", "answer" => "a" } ])
    @topic.reload

    assert_equal :array_ok, FaqPayloadNormalizer.classify(@topic.faqs)
    assert_equal 1, @topic.faq_list.size
    assert_equal 0, FaqPayloadNormalizer.authored_count(@topic.faqs) - @topic.faq_list.size
  end

  test "FAQ 가 없는 토픽은 EMPTY 이지 결함이 아니다" do
    @topic.update_column(:faqs, [])
    @topic.reload
    assert_equal :empty, FaqPayloadNormalizer.classify(@topic.faqs)

    @topic.update_column(:faqs, nil)
    @topic.reload
    assert_equal :empty, FaqPayloadNormalizer.classify(@topic.faqs)
  end

  # ── 정규화가 실제로 소실을 되돌리는가 ──
  test "정규화하면 잃었던 FAQ 가 도달 가능해진다" do
    raw = '[{"answer"=>"추정가격에 따라 다릅니다", "question"=>"입찰공고 기간은?"}, {"answer"=>"5일 이상", "question"=>"재공고 기간은?"}]'
    @topic.update_column(:faqs, raw)
    @topic.reload
    assert_equal 0, @topic.faq_list.size

    status, value = FaqPayloadNormalizer.call(@topic.faqs)
    assert_equal :ok, status
    assert FaqPayloadNormalizer.preserves_source?(raw, value), "복원값이 원문 부분문자열이 아니면 내용이 바뀐 것"

    @topic.update_column(:faqs, value)
    @topic.reload

    assert_equal 2, @topic.faq_list.size
    assert_equal "입찰공고 기간은?", @topic.faq_list.first["question"]
  end

  # ── category 고아 검출기 ──
  # ⚠️ 로컬 배열에 값이 있나 없나만 보는 테스트는 동어반복이다(독립검증 LOW 지적).
  #    lint 가 실제로 쓰는 경로 — **라우트에서 읽은 허용값 + ActiveRecord 쿼리** — 를 그대로 태운다.
  def orphan_scope
    allowed = Rails.application.routes.routes
                   .find { |r| r.name == "topics_category" }
                   .requirements[:key].source.delete("^a-z|").split("|").reject(&:empty?)
    Topic.where.not(category: allowed).or(Topic.where(category: nil))
  end

  test "양성대조 — 라우트 밖 category 를 심으면 탐지 쿼리가 잡는다" do
    @topic.update_column(:category, "입찰")
    assert_includes orphan_scope.pluck(:slug), @topic.slug
  end

  test "음성대조 — 허용값 category 는 탐지 쿼리에 걸리지 않는다" do
    @topic.update_column(:category, "contract")
    assert_not_includes orphan_scope.pluck(:slug), @topic.slug
  end

  test "양성대조 — category 가 nil 이어도 고아로 잡힌다" do
    @topic.update_column(:category, nil)
    assert_includes orphan_scope.pluck(:slug), @topic.slug
  end

  test "topics_category 라우트 constraint 가 허용값 정본이다" do
    route = Rails.application.routes.routes.find { |r| r.name == "topics_category" }
    assert_not_nil route, "허용값 정본이 사라지면 lint 가 추측하게 된다"

    keys = route.requirements[:key].source.delete("^a-z|").split("|").reject(&:empty?)
    assert_equal %w[budget contract duty expense other property salary subsidy travel], keys.sort
  end
end
