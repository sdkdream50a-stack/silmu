# frozen_string_literal: true

require "test_helper"

# 2026-09-28 비도구 콘텐츠 신뢰 감사 법령 정정 회귀.
# 원문 근거는 마이그레이션 머리말(law.go.kr DRF URL) 참조.
class NontoolLegalContentFixesTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260928230000_nontool_legal_content_fixes.rb")
  SRC = MIGRATION.read
  GUIDE_OLD = eval(SRC[/^guide_old = (\{.*?\n\})\n/m, 1]).freeze # rubocop:disable Security/Eval
  GUIDE_NEW = eval(SRC[/^guide_new = (\{.*?\n\})\n/m, 1]).freeze # rubocop:disable Security/Eval

  # 운영(2026-09-28 fresh-read)과 같은 모양의 옛 값
  LEAVE_OLD_LAW = <<~MD
    ## 관련 조문 원문

    이 탭은 법령 원문만 싣습니다.

    ### 국가공무원법 제71조(휴직)

    ① 공무원이 다음 각 호의 어느 하나에 해당하면 임용권자는 본인의 의사에도 불구하고 휴직을 명하여야 한다.

    ### 국가공무원법 제72조(휴직 기간)

    휴직 기간은 다음과 같다.
  MD
  LEAVE_OLD_QS = [
    { "label" => "질병휴직", "value" => "1년 이내(최대 2년)", "note" => "국가공무원법 제72조 · 봉급 70%" },
    { "label" => "공무상 질병", "value" => "3년 이내", "note" => "봉급 전액" },
    { "label" => "육아휴직", "value" => "자녀 1명당 3년 이내", "note" => "국가공무원법 제71조" },
    { "label" => "무급 휴직", "value" => "간호·학업·동반·자기개발", "note" => "원칙 봉급 미지급" }
  ].freeze
  CASES = {
    "quote-collection-same-vendor-double" => "지방계약법 시행령 제25조 제1항 제5호 (소액 수의계약), 행정안전부 예규 제2023-24호 제5장 제3절 (2인 이상 견적서 징구 기준)",
    "qualification-failure-wrong-award" => "지방계약법 시행령 제42조 (낙찰자 결정), 지방계약법 시행령 제42조제2항 (적격심사 기준), 행정안전부 예규 제2023-24호 제4장 제3절 (적격심사 세부 기준)",
    "private-contract-split-over-limit" => "지방계약법 시행령 제25조 제1항 제5호 (소액 수의계약), 지방계약법 시행령 제77조 (계약 분할 금지), 행정안전부 예규 제2023-24호 제5장 제2절 (계약 분할 금지 기준)"
  }.freeze
  CHILDCARE_OLD = "2025년 1월 3일 「공무원수당 등에 관한 규정」 §11의3 ③·④이 삭제되며 육아휴직수당의 사후지급분(복직 후 잔여분 일시 지급) 제도가 폐지되었습니다. 부칙 일반 적용례에 따라 2025년 1월 1일 이후 지급분부터 신규 규정이 적용됩니다."

  setup do
    @guide = Guide.new(slug: "private-contract-limit-guide", title: "수의계약 한도액 가이드", category: "계약", view_count: 444)
    GUIDE_OLD.each { |k, v| @guide[k] = v }
    @guide.save!(validate: false)
    Topic.new(slug: "leave-of-absence", name: "휴직", law_content: LEAVE_OLD_LAW, quick_stats: LEAVE_OLD_QS, view_count: 912).save!(validate: false)
    Topic.new(slug: "edu-childcare-pay-2025-revision", name: "육아휴직수당", summary: CHILDCARE_OLD).save!(validate: false)
    CASES.each { |slug, lb| AuditCase.new(slug: slug, title: slug, legal_basis: lb, published: true).save!(validate: false) }
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def guide_text
    g = Guide.find_by!(slug: "private-contract-limit-guide")
    [ g.summary, g.description, g.sections.to_json ].join
  end

  test "P0: 수의계약 한도액 가이드에서 없는 «연간 누계 한도» 가 사라지고 건별 한도 원문이 들어간다" do
    migrate
    text = guide_text
    assert_not_includes text, "연간 수의계약 누계 5천만원"
    assert_not_includes text, "연간 수의계약 누계 2억원"
    assert_not_includes text, "상위 결재권자의 승인"
    assert_includes text, "제25조제1항제5호나목"
    assert_includes text, "추정가격이 2천만원 초과 1억원 이하인 계약으로서"
    assert_includes text, "행정안전부 예규 제372호"
    assert_includes text, "연간 수의계약 누계 금액 한도가 없습니다"
    assert_includes text, "[참고 · 시행 전]"
    assert_includes text, "hankyung.com/article/2026081300501"
    g = Guide.find_by!(slug: "private-contract-limit-guide")
    assert_equal Date.new(2026, 9, 28), g.last_verified_at.to_date
    assert_operator g.verification_source.length, :<=, 200
    assert_equal 444, g.view_count
  end

  test "P1: 휴직 토픽 원문 탭에 지방공무원법 제63조·제64조가 국가 조문보다 먼저, 국가는 참고로" do
    migrate
    t = Topic.find_by!(slug: "leave-of-absence")
    law = t.law_content
    assert_includes law, "### 지방공무원법 제63조(휴직)"
    assert_includes law, "② 공무원이 다음 각 호의 어느 하나에 해당하는 사유로 휴직을 원하면 임용권자는 휴직을 명할 수 있다. 다만, 제4호의 경우에는"
    assert_includes law, "8. 제63조제2항제4호에 따른 휴직기간은 자녀 1명에 대하여 3년 이내로 한다."
    assert_includes law, "## 국가공무원 기준(참고)"
    assert_operator law.index("### 지방공무원법 제63조"), :<, law.index("### 국가공무원법 제71조")
    assert_equal 1, law.scan("### 국가공무원법 제71조(휴직)").size
    notes = t.quick_stats.map { |q| q["note"] }
    assert_includes notes, "지방공무원법 제64조 · 봉급 70%"
    assert_includes notes, "지방공무원법 제64조"
    assert_not(notes.any? { |n| n.include?("국가공무원법") })
    assert_equal 912, t.view_count
  end

  test "P1/P2: 감사사례 예규 번호와 육아휴직수당 지방 규정" do
    migrate
    CASES.each_key { |slug| assert_not_includes AuditCase.find_by!(slug: slug).legal_basis, "2023-24" }
    assert_includes AuditCase.find_by!(slug: "quote-collection-same-vendor-double").legal_basis, "행정안전부 예규 제231호) 제5장 제3절"
    assert_includes AuditCase.find_by!(slug: "private-contract-split-over-limit").legal_basis, "행정안전부 예규 제252호) 제1장 제1절 5. (분할계약의 금지)"
    assert_includes AuditCase.find_by!(slug: "qualification-failure-wrong-award").legal_basis, "「지방자치단체 입찰시 낙찰자 결정기준」(행정안전부 예규 제253호)"
    summary = Topic.find_by!(slug: "edu-childcare-pay-2025-revision").summary
    assert_includes summary, "제11조의2 ③·④도 같은 날(대통령령 제35184호) 삭제"
    assert_includes summary, "부칙 제6조"
  end

  test "DRY_RUN 은 바꿀 필드만 출력하고 쓰지 않는다 · 두 번째 실행은 0건" do
    out = migrate("DRY_RUN" => "1")
    assert_includes out, "fields_to_change=summary,description,sections,last_verified_at,verification_method,verification_source"
    assert_includes out, "DRY_RUN changes=12"
    assert_includes guide_text, "연간 수의계약 누계 5천만원"

    assert_includes migrate, "changes=12"
    assert_includes migrate, "changes=0"
    assert_equal 1, Topic.find_by!(slug: "leave-of-absence").law_content.scan("### 지방공무원법 제63조(휴직)").size
  end

  test "운영 값이 예상과 다르면 전부 롤백한다" do
    AuditCase.find_by!(slug: "qualification-failure-wrong-award").update_columns(legal_basis: "다른 값")
    assert_raises(RuntimeError) { migrate }
    assert_includes guide_text, "연간 수의계약 누계 5천만원"
  end

  test "seed 원본도 같은 정정을 담는다 (전체 seed 재실행 없이 파일만 적재)" do
    Guide.where(slug: "private-contract-limit-guide").delete_all
    capture_io { load Rails.root.join("db/seeds/guides.rb") }
    g = Guide.find_by!(slug: "private-contract-limit-guide")
    assert_equal GUIDE_NEW["sections"], g.sections
    assert_equal GUIDE_NEW["summary"], g.summary

    Topic.where(slug: "leave-of-absence").delete_all
    capture_io { load Rails.root.join("db/seeds/topics/leave_of_absence.rb") }
    assert_includes Topic.find_by!(slug: "leave-of-absence").law_content, "### 지방공무원법 제64조(휴직기간)"

    capture_io { load Rails.root.join("db/seeds/edu_childcare_pay_2025_revision.rb") }
    assert_includes Topic.find_by!(slug: "edu-childcare-pay-2025-revision").summary, "대통령령 제35184호"

    assert_not_includes Rails.root.join("db/seeds/audit_cases/topic_audit_cases_batch_01.rb").read, "제2023-24호"
    assert_not_includes Rails.root.join("db/seeds/topic_quick_stats_backfill_2026_06_03_batch2.rb").read, "국가공무원법 제72조 · 봉급"
  end

  # 동일 업체 «연간 수의계약 누적 한도»는 현행 법령에 없다(2026-09-28 원문 대조) — 시험 해설·뉴스레터에도 남기지 않는다.
  test "시험 문제·뉴스레터 체크포인트에 없는 «연간 수의계약 누적 한도»를 전제하지 않는다" do
    %w[app/models/exam_questions.rb config/newsletter_checkpoints.yml].each do |path|
      src = Rails.root.join(path).read
      [ "연간 수의계약 한도", "연간 한도 회피", "누적 한도", "누적 금액이 한도" ].each do |phrase|
        assert_not_includes src, phrase, "#{path} 가 없는 연간 누적 한도를 전제함: #{phrase}"
      end
    end
  end
end
