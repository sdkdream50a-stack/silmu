# frozen_string_literal: true

require "test_helper"

# 감사사례 Truth Closure G1 (2026-09-29) — 경기도교육청 2021 사례집 재구성 사례 P0·P1 정정 회귀.
# 운영 모양 = 시드(정정 후)에서 edits 를 거꾸로 되돌리고, 처분 절(20260918000000·010000 이 만든 문구)과
# 운영 적용 대상(PUBLIC_SCHOOL·HIGH)·출처 쪽수(p.86)를 입힌 상태. 마이그레이션 결과가 정정된 시드와 같아야 한다.
class AuditTruthG1Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929100000_audit_truth_g1.rb")
  EDITS = eval(MIGRATION.read[/^edits = \[.*?^\]\.freeze/m].sub(/^edits = /, "")) # rubocop:disable Security/Eval
  SEEDS = %w[
    goe_2021_budget_execution_audit_cases goe_2021_school_contracts_pre_audit_cases goe_2021_school_accounting_basics_audit_cases
    goe_2021_school_funds_audit_cases goe_2021_compensation_audit_cases goe_2021_property_audit_cases goe_2021_supplies_audit_cases
    content_enrichment_phase2_edu_accounting_5_2026_05_18 content_enrichment_phase2_edu_accounting_rest_10_2026_05_18
    content_enrichment_phase2_edu_rest_14_2026_05_19 content_enrichment_phase2_edu_etc_16_2026_05_18
  ].freeze
  # 운영 처분 절은 시드가 아니라 20260918000000·010000 이 쓴다 — 같은 문구를 입힌다(새 문구 = 이 마이그레이션의 NEW).
  DISPOSITIONS = {
    "goe-2021-beneficiary-cost-direct-use" => "관련자 주의",
    "goe-2021-suspension-pay-deduction" => "관련자 주의, 과소지급액 추가지급 및 과다지급액 회수"
  }.freeze
  FIELDS = %w[issue lesson detail legal_basis].freeze
  HIDDEN = %w[goe-2021-budget-formation-violation goe-2021-suspense-cash-management].freeze # 운영 «적용 대상» 미표시
  AGENCY = {
    "goe-2021-credit-card-self-inspection" => [ [ "EDUCATION_OFFICE" ], "HIGH" ],
    "goe-2021-daily-audit-89-cases" => [ [ "EDUCATION_SUPPORT_OFFICE" ], "HIGH" ],
    "goe-2021-suspense-cash-single-approval" => [ [ "EDUCATION_SUPPORT_OFFICE" ], "HIGH" ],
    "goe-2021-budget-formation-violation" => [ [], "LOW" ],
    "goe-2021-contract-method-2stage-bidding" => [ [], "LOW" ],
    "goe-2021-credit-card-payment-account" => [ [], "LOW" ],
    "goe-2021-deemed-budget-violation" => [ [], "LOW" ],
    "goe-2021-explicit-carryover-violation" => [ [], "LOW" ],
    "goe-2021-suspense-cash-management" => [ [], "LOW" ],
    "goe-2021-temporary-building-violation" => [ [], "LOW" ],
    "goe-2021-vehicle-management-failure" => [ [], "LOW" ]
  }.freeze
  SLUGS = (EDITS.map(&:first) + AGENCY.keys).uniq.freeze
  SECTION = /(^\#{2,3} 처분(?: 결과)?[ \t]*\n)(.*?)(?=^\#{1,3} |\z)/m

  setup do
    capture_io { SEEDS.each { |f| load Rails.root.join("db/seeds/audit_cases/#{f}.rb") } }
    DISPOSITIONS.each do |slug, disposition|
      ac = AuditCase.find_by!(slug: slug)
      note = "- 사례집 원문 처분: «#{disposition}» (경기도교육청 감사사례집, 2021)\n"
      ac.update_columns(detail: ac.detail.sub(SECTION) { "#{Regexp.last_match(1)}#{note}\n" })
    end
    @expected = SLUGS.to_h { |s| [ s, snapshot(s) ] }
    @expected.each do |slug, snap|
      # 처분 절 NEW 는 시드에 없다 — 기대값에만 새 문구를 반영한다
      EDITS.select { |s, f, old, _| s == slug && f == "detail" && snap["detail"].include?(old) && DISPOSITIONS.key?(slug) && old.start_with?("사례집 원문 처분") }
           .each { |_, _, old, new| snap["detail"] = snap["detail"].sub(old) { new } }
    end
    SLUGS.each do |slug|
      reverted = FIELDS.to_h { |f| [ f, revert(AuditCase.find_by!(slug: slug).read_attribute(f).to_s, slug, f) ] }
      agency = HIDDEN.include?(slug) ? { target_agency: [], agency_scope_confidence: nil } : { target_agency: [ "PUBLIC_SCHOOL" ], agency_scope_confidence: "HIGH" }
      AuditCase.find_by!(slug: slug).update_columns(reverted.merge(agency))
    end
    ac = AuditCase.find_by!(slug: "goe-2021-credit-card-self-inspection")
    ac.update_columns(source_page: 86, source: ac.source.merge("page" => 86))
  end

  def snapshot(slug)
    ac = AuditCase.find_by!(slug: slug)
    FIELDS.to_h { |f| [ f, ac.read_attribute(f).to_s ] }.merge("title" => ac.title, "view_count" => ac.view_count)
  end

  def revert(value, slug, field)
    EDITS.select { |s, f, _, _| s == slug && f == field }.reverse_each { |_, _, old, new| value = value.sub(new) { old } }
    value
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def body(slug)
    ac = AuditCase.find_by!(slug: slug)
    FIELDS.map { |f| ac.read_attribute(f).to_s }.join("\n")
  end

  STALE = {
    "goe-2021-budget-formation-violation" => [ "30일 전(2.1)", "3월 이후 편성은 무효.", "위반 시 예산 무효" ],
    "goe-2021-bid-announcement-period" => [ "주된 영업소가 납품지가 소재하는", "건설기술용역 2.1억, 안전점검 1.5억, 그 외 3.3억):", "단일 시·도만 가능" ],
    "goe-2021-contract-method-2stage-bidding" => [ "6억원 초과 계약은 학교운영위 사전 심의", "기술 평가가 가격보다 중요한 사업", "거의 확정적으로 분류" ],
    "goe-2021-daily-audit-89-cases" => [ "누적 133건(89+44)", "3년간 누적 133건", "매년 30건 이상", "결재라인 묵인", "평균 연간 위반: 약 44건" ],
    "goe-2021-credit-card-payment-account" => [ "2024.3월~2025.5월", "분기 1회", "회계연도 독립 원칙 추가 위반에 해당합니다" ],
    "goe-2021-credit-card-self-inspection" => [ "(p.86)" ],
    "goe-2021-explicit-carryover-violation" => [ "사후 학교운영위 보고 |", "1학기 내 집행이 원칙", "2년 연속 이월은 사실상" ],
    "goe-2021-suspense-cash-embezzlement" => [ "국가공무원법 §82·83", "시스템 결함의 직접 원인이 된 중대 사례" ],
    "goe-2021-suspense-cash-management" => [ "정상 회계 외 거래로 가중 처벌", "징수권 행사 의무 회피라는 추가 위반" ],
    "goe-2021-suspense-cash-single-approval" => [ "약 2년간 357건", "재이관 포함" ],
    "goe-2021-suspension-pay-deduction" => [ "일부만 감액한 사례", "신규채용·승진 등 임용 시 발령일 기준 월액 일할계산을 적용하지 않은 사례" ],
    "goe-2021-temporary-building-violation" => [ "신규 설치 시 별도 허가", "감독청(시·군·구청장)", "30~40개동", "5년 이상 추정", "연결 시 별도 허가" ],
    "goe-2021-vehicle-management-failure" => [ "30km 이상이면", "사유서가 첨부", "견책 이상 징계", "소관 공용차량 관리 규칙 최신본" ]
  }.freeze

  FRESH = {
    "goe-2021-beneficiary-cost-direct-use" => [ "«관련자 경고»(방과후 특강 수강료 346,320천원" ],
    "goe-2021-budget-formation-violation" => [ "(3.1 개시 기준 1월 말)", "원문은 «2월 중 정리추경»" ],
    "goe-2021-bid-announcement-period" => [ "법인등기부상 본점소재지", "시행규칙 제24조", "시행규칙 제25조③ 단서" ],
    "goe-2021-contract-method-2stage-bidding" => [ "계약의 특성상 필요하다고 인정되는 경우(지방계약법 시행령 제18조)", "원문·법령에서 확인되지 않습니다" ],
    "goe-2021-daily-audit-89-cases" => [ "중복 여부 원문 미기재", "원문 처분은 «기관경고»" ],
    "goe-2021-credit-card-self-inspection" => [ "(p.87)", "(실무 예시 · 원문 외)" ],
    "goe-2021-explicit-carryover-violation" => [ "경기도 공립학교회계 규칙 제19조②" ],
    "goe-2021-suspense-cash-embezzlement" => [ "지방공무원법 §69·§70·§71" ],
    "goe-2021-suspense-cash-single-approval" => [ "감사대상 기간 중 세입세출외현금 반환 357건" ],
    "goe-2021-suspension-pay-deduction" => [ "3,553,730원", "«현지조치, 과다지급액 회수»", "제11조의3은 개정되어 사후지급분 삭제" ],
    "goe-2021-temporary-building-violation" => [ "시행령 §15①3", "제5조의2⑥", "축조 시기: 알 수 없음(원문)" ],
    "goe-2021-vehicle-management-failure" => [ "공무용 차량 관리 규칙", "원문 처분은 «관련자 주의»" ]
  }.freeze

  test "되돌린 상태가 실제로 옛 문구·공립학교 표시를 담고 있다(구 상태 = 실패 조건 재현)" do
    STALE.each { |slug, list| list.each { |stale| assert_includes body(slug), stale, "#{slug}: #{stale}" } }
    assert_includes body("goe-2021-beneficiary-cost-direct-use"), "사례집 원문 처분: «관련자 주의» (경기도교육청"
    assert_equal [ "PUBLIC_SCHOOL" ], AuditCase.find_by!(slug: "goe-2021-daily-audit-89-cases").target_agency
    assert_equal 86, AuditCase.find_by!(slug: "goe-2021-credit-card-self-inspection").source_page
  end

  test "NORMAL: 결과가 정정된 시드와 같고 slug·title·view_count 는 그대로다" do
    migrate
    SLUGS.each do |slug|
      assert_equal @expected[slug], snapshot(slug), slug
    end
  end

  test "POSITIVE/NEGATIVE: 새 문구가 있고 틀린 값은 없다" do
    migrate
    FRESH.each { |slug, list| list.each { |fresh| assert_includes body(slug), fresh, "#{slug}: #{fresh}" } }
    STALE.each { |slug, list| list.each { |stale| assert_not_includes body(slug), stale, "#{slug}: #{stale}" } }
    # 틀린 값 대조군: 30일 전을 2월로·지역제한을 «주된 영업소»로·정직 처분을 «관련자 주의» 하나로 되돌린 문구가 없다
    assert_no_match(/30일 전\(2\.\d+\)/, body("goe-2021-budget-formation-violation"))
    assert_not_includes body("goe-2021-bid-announcement-period"), "주된 영업소가 납품지"
    assert_not_includes body("goe-2021-suspension-pay-deduction"), "사례집 원문 처분: «관련자 주의, 과소지급액 추가지급 및 과다지급액 회수» (경기도교육청"
    # 다른 사례(카드대금 계좌)는 원래 p.86 이 맞다 — 쪽수 정정이 번지지 않는다
    assert_includes body("goe-2021-credit-card-payment-account"), "(p.86)"
  end

  test "적용 대상: 교육지원청·직속기관은 해당 코드, 혼재·미특정은 비우고 LOW(표시 안 함)" do
    migrate
    AGENCY.each do |slug, (agencies, confidence)|
      ac = AuditCase.find_by!(slug: slug)
      assert_equal agencies, ac.target_agency, slug
      assert_equal confidence, ac.agency_scope_confidence, slug
      agencies.each { |code| assert AgencyScope::AGENCY_TYPES.key?(code), code }
    end
    assert AuditCase.find_by!(slug: "goe-2021-daily-audit-89-cases").show_agency_scope?
    assert_equal [ "교육지원청" ], AuditCase.find_by!(slug: "goe-2021-daily-audit-89-cases").target_agency_labels
    assert_not AuditCase.find_by!(slug: "goe-2021-vehicle-management-failure").show_agency_scope?
    ac = AuditCase.find_by!(slug: "goe-2021-credit-card-self-inspection")
    assert_equal 87, ac.source_page
    assert_equal 87, ac.source["page"]
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 61, EDITS.size
    assert_match(/changes=73\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| [ body(s), AuditCase.find_by!(slug: s).target_agency ] }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=73\b/, out)
    assert_match(%r{AuditCase/goe-2021-temporary-building-violation fields_to_change=lesson,detail,target_agency,agency_scope_confidence}, out)
    assert_equal before, SLUGS.map { |s| [ body(s), AuditCase.find_by!(slug: s).target_agency ] }
  end

  test "NEGATIVE: 한 사례의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    ac = AuditCase.find_by!(slug: "goe-2021-vehicle-management-failure")
    ac.update_columns(detail: ac.detail.sub("견책 이상 징계", "감봉 이상 징계"))
    untouched = body("goe-2021-beneficiary-cost-direct-use")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("goe-2021-beneficiary-cost-direct-use"), "한 사례가 어긋났는데 다른 사례는 써졌다 — 전체 롤백이 아니다"
    assert_equal [ "PUBLIC_SCHOOL" ], AuditCase.find_by!(slug: "goe-2021-daily-audit-89-cases").target_agency
  end

  test "NEGATIVE: 적용 대상이 운영 지문(공립학교)과 다르면 멈춘다" do
    AuditCase.find_by!(slug: "goe-2021-daily-audit-89-cases").update_columns(target_agency: [ "PRIVATE_SCHOOL" ])
    assert_raises(RuntimeError) { migrate }
  end

  test "시드 원천에도 옛 문구가 남지 않는다" do
    seeded = SEEDS.map { |f| Rails.root.join("db/seeds/audit_cases/#{f}.rb").read }.join
    [ "30일 전(2.1)", "6억원 초과 계약은 학교운영위 사전 심의", "신규 설치 시 별도 허가", "국가공무원법 §82·83",
      "누적 133건(89+44)", "2024.3월~2025.5월", "30~40개동 추정", "단일 시·도만 가능" ].each do |stale|
      assert_not_includes seeded, stale
    end
  end
end
