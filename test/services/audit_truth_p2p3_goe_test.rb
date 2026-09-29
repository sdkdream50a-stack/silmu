# frozen_string_literal: true

require "test_helper"

# 감사사례 P2/P3 정정 goe batch (2026-09-29) — 경기도교육청 2021 사례집 재구성 사례 회귀.
# 운영 모양 = 시드(정정 후)에서 edits 를 거꾸로 되돌리고 운영 적용 대상(PUBLIC_SCHOOL·HIGH)을 입힌 상태.
# 마이그레이션 결과가 정정된 시드와 같아야 한다(시드·운영 동기).
class AuditTruthP2p3GoeTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929120000_audit_truth_p2p3_goe.rb")
  sponsor = "경기도 공립학교회계 규칙 §21, 2024-12-19 개정" # edits 안의 #{sponsor} 보간용
  EDITS = eval(MIGRATION.read[/^edits = \[.*?^\]\.freeze/m].sub(/^edits = /, "")) # rubocop:disable Security/Eval
  SEEDS = %w[
    goe_2021_budget_execution_audit_cases goe_2021_school_contracts_pre_audit_cases goe_2021_school_accounting_basics_audit_cases
    goe_2021_school_funds_audit_cases goe_2021_compensation_audit_cases goe_2021_property_audit_cases goe_2021_supplies_audit_cases
    content_enrichment_phase2_edu_accounting_5_2026_05_18 content_enrichment_phase2_edu_accounting_rest_10_2026_05_18
    content_enrichment_phase2_edu_rest_14_2026_05_19 content_enrichment_phase2_edu_etc_16_2026_05_18
    content_enrichment_phase2_edu_private_contract_7_2026_05_18
  ].freeze
  FIELDS = %w[issue lesson detail legal_basis].freeze
  AGENCY = %w[goe-2021-budget-transfer-violation goe-2021-business-promotion-improper
              goe-2021-contract-review-omission goe-2021-instructor-allowance-improper].freeze
  SLUGS = (EDITS.map(&:first) + AGENCY).uniq.freeze
  # 목록 밖(P0/P1 · 이미 정정된 G1) 사례 — 이 마이그레이션이 건드리면 안 된다
  CONTROLS = %w[goe-2021-credit-card-self-inspection goe-2021-vehicle-management-failure goe-2021-daily-audit-89-cases
                goe-2021-budget-formation-violation goe-2021-suspense-cash-management goe-2021-beneficiary-cost-direct-use
                goe-2021-development-fund-misuse goe-2021-supplies-selection-committee goe-2021-travel-expense-improper].freeze

  setup do
    capture_io { SEEDS.each { |f| load Rails.root.join("db/seeds/audit_cases/#{f}.rb") } }
    @expected = SLUGS.to_h { |s| [ s, snapshot(s) ] }
    SLUGS.each do |slug|
      reverted = FIELDS.to_h { |f| [ f, revert(AuditCase.find_by!(slug: slug).read_attribute(f).to_s, slug, f) ] }
      AuditCase.find_by!(slug: slug).update_columns(reverted.merge(target_agency: [ "PUBLIC_SCHOOL" ], agency_scope_confidence: "HIGH", view_count: 170))
    end
    AuditCase.where(slug: CONTROLS).update_all(target_agency: [ "PUBLIC_SCHOOL" ], agency_scope_confidence: "HIGH")
  end

  def snapshot(slug)
    a = AuditCase.find_by!(slug: slug)
    FIELDS.to_h { |f| [ f, a.read_attribute(f).to_s ] }.merge("title" => a.title, "slug" => a.slug)
  end

  def revert(value, slug, field)
    EDITS.select { |s, f, _, _| s == slug && f == field }.reverse.each { |_, _, old, new| value = value.sub(new) { old } }
    value
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def body(slug)
    a = AuditCase.find_by!(slug: slug)
    FIELDS.map { |f| a.read_attribute(f).to_s }.join("\n")
  end

  STALE = {
    "goe-2021-accounting-disorder-construction" => [ "실질적으로 부재했음을 의미", "분할 의혹이 자동으로 발생", "2024-04-25 시행본" ],
    "goe-2021-annual-leave-compensation-mispayment" => [ "(p.129)", "약 1,490만원 (3개 사례)", "3년간 1,490만원 규모" ],
    "goe-2021-bad-debt-write-off-violation" => [ "급식비 등은 1년 시효에 해당", "미수납 발생 후 약 6개월" ],
    "goe-2021-beneficiary-cost-settlement" => [ "정산·공개 절차 (사업 종료 10일 이내)", "| 정산 기한 | 사업 종료 10일 이내 |", "학교운영위의 법적 권한을 우회" ],
    "goe-2021-budget-account-mixed-execution" => [ "누적 부적정 집행 규모 약 2,260만원" ],
    "goe-2021-budget-transfer-violation" => [ "통상 14일 전 안건 통지", "거의 모두 의도성 입증", "견책 이상 처분 + 변상 책임" ],
    "goe-2021-building-registration-delay" => [ "60일 카운트다운 시작점" ],
    "goe-2021-business-promotion-improper" => [ "카드 사용 불가 지역에 한정", "횡령 직전", "적발 누적 규모 폭증" ],
    "goe-2021-clothing-expense-improper" => [ "1,840만원 (가상)", "무기계약근로자 관리 규정 적용" ],
    "goe-2021-condolence-money-improper" => [ "부정청탁법까지 적용 가능", "분할 지급으로 회피 시도도 위반" ],
    "goe-2021-contract-review-omission" => [ "견책 이상 처분 + 변상 책임" ],
    "goe-2021-development-fund-handover" => [ "통상 행정실장" ],
    "goe-2021-development-fund-misclassified" => [ "지방회계법 + 회계관리에 관한 규칙", "분기 결산 공시", "학교운영위 회비 일시 보관" ],
    "goe-2021-disposal-procedure-violation" => [ "위 두 예외에 해당하지 않으면", "4. 입찰 공고 (최소 1주일)" ],
    "goe-2021-failed-bid-private-contract" => [ "행안부 예규 「지방자치단체 입찰 및 계약 집행기준」은 유찰 후", "학부모회 정보공개 요청", "무효" ],
    "goe-2021-improper-payee-cleaning-service" => [ "지방계약법 시행령은 대가 지급" ],
    "goe-2021-improper-payee-personal-card" => [ "지방계약법·교육비특별회계", "[[goe-2021-credit-card-usage-improper]]" ],
    "goe-2021-instructor-allowance-improper" => [ "인사혁신처 예규" ],
    "goe-2021-special-duty-allowance-mispayment" => [ "(p.126)", "약 1,131만원", "30개 학교", "자동 차감되지 않", "자동 차감 안 됨" ],
    "goe-2021-split-after-school-program" => [ "강하게 시사", "형법 §227" ],
    "goe-2021-split-care-trip-copier-paint" => [ "1인 견적 수의계약으로 처리", "G2B 입찰 없이 1인 견적", "정확히 걸치도록" ],
    "goe-2021-supplies-joint-purchase" => [ "10~20%", "중점대상 품목이라도 다음 경우 자체 구매가 가능합니다" ],
    "goe-2021-tenure-allowance-mispayment" => [ "(PDF §확인사항)", "회의자료" ],
    "goe-2021-vending-machine-fee-miscalculation" => [ "물품관리법", "매점 자동판매기 수익·사용허가" ]
  }.freeze

  FRESH = {
    "goe-2021-accounting-disorder-construction" => [ "확인되지 않는 시간 간격", "원문은 추가 물품계약 사실만 지적", "2024-02-17 시행본" ],
    "goe-2021-annual-leave-compensation-mispayment" => [ "(p.130)", "「지방공무원 수당 등에 관한 규정」 §18의5 (교육공무원 제외 단서 확인)", "과다·근거없는 지급 12,865,810원" ],
    "goe-2021-beneficiary-cost-settlement" => [ "정산 후 10일 이내 정산내역 공개", "§21, 2024-12-19 개정", "학교운영위 보고(권장)" ],
    "goe-2021-budget-account-mixed-execution" => [ "총 11건 16,236,180원(원문은 두 유형 합산)", "약 2,264만원" ],
    "goe-2021-budget-transfer-violation" => [ "회의 7일 전까지, 경기도 공립학교회계 규칙 §13①" ],
    "goe-2021-building-registration-delay" => [ "소관에 속하게 된 날(공유재산 및 물품 관리법 시행령 §6)" ],
    "goe-2021-disposal-procedure-violation" => [ "국가나 다른 지방자치단체에 매각하는 경우", "시행령 제78조③" ],
    "goe-2021-failed-bid-private-contract" => [ "시행령 제19조③·제26조③", "부적정 수의계약" ],
    "goe-2021-improper-payee-cleaning-service" => [ "재무회계 규칙 §68①, 경기도 공립학교회계 규칙 §34" ],
    "goe-2021-improper-payee-personal-card" => [ "재무회계 규칙 §68①·세출예산 집행기준에 따라" ],
    "goe-2021-special-duty-allowance-mispayment" => [ "(p.127)", "약 1,161만원(11,613,360원)", "31개 학교(중복 여부는 원문 미표기)", "자동 차감 여부는 원문에 없음" ],
    "goe-2021-split-after-school-program" => [ "관련자 주의·관리자(교장) 경고까지만 서술" ],
    "goe-2021-split-care-trip-copier-paint" => [ "입찰방식을 거치지 않고 수의계약", "14,631천원과 9,958천원으로 분할한 사실을 지적", "실무 해석 — 원문 근거 없음" ],
    "goe-2021-supplies-joint-purchase" => [ "해당 연도 공문 확인 필요(원문 미제시)" ],
    "goe-2021-tenure-allowance-mispayment" => [ "근거 요지(원문 p.126 관련자 요건)" ],
    "goe-2021-vending-machine-fee-miscalculation" => [ "공유재산 및 물품 관리법", "매점 및 자동판매기 사용ㆍ수익허가에 관한 조례" ]
  }.freeze

  test "되돌린 상태가 실제로 옛 문구를 담고 있다(구 코드 = 실패 조건 재현)" do
    STALE.each { |slug, list| list.each { |stale| assert_includes body(slug), stale, "#{slug}: #{stale}" } }
    AGENCY.each { |slug| assert_equal [ "공립학교" ], AuditCase.find_by!(slug: slug).target_agency_labels }
  end

  test "NORMAL: 마이그레이션 결과가 정정된 시드와 같고 slug·title·view_count 는 그대로다" do
    migrate
    SLUGS.each do |slug|
      a = AuditCase.find_by!(slug: slug)
      FIELDS.each { |f| assert_equal @expected[slug][f], a.read_attribute(f).to_s, "#{slug} #{f}" }
      assert_equal @expected[slug]["title"], a.title
      assert_equal slug, a.slug
      assert_equal 170, a.view_count
    end
  end

  test "POSITIVE/NEGATIVE: 새 근거 문구가 있고 옛 단정·오귀속·창작 수치는 없다" do
    migrate
    FRESH.each { |slug, list| list.each { |fresh| assert_includes body(slug), fresh, "#{slug}: #{fresh}" } }
    STALE.each { |slug, list| list.each { |stale| assert_not_includes body(slug), stale, "#{slug}: #{stale}" } }
    assert_no_match(/\[\[goe-/, SLUGS.map { |s| body(s) }.join("\n"), "위키 마크업 노출")
  end

  test "target_agency: 적용 대상 혼재 4건만 [] + LOW, 나머지는 운영값 유지" do
    migrate
    AGENCY.each do |slug|
      a = AuditCase.find_by!(slug: slug)
      assert_equal [], a.target_agency, slug
      assert_equal "LOW", a.agency_scope_confidence, slug
      assert_empty a.target_agency_labels, slug
    end
    (SLUGS - AGENCY).each do |slug|
      a = AuditCase.find_by!(slug: slug)
      assert_equal [ [ "PUBLIC_SCHOOL" ], "HIGH" ], [ a.target_agency, a.agency_scope_confidence ], slug
    end
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 71, EDITS.size
    assert_match(/changes=75\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| [ body(s), AuditCase.find_by!(slug: s).target_agency ] }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=75\b/, out)
    assert_match(%r{AuditCase/goe-2021-budget-transfer-violation fields_to_change=lesson,target_agency,agency_scope_confidence}, out)
    assert_equal before, SLUGS.map { |s| [ body(s), AuditCase.find_by!(slug: s).target_agency ] }
  end

  test "NEGATIVE: 한 사례의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    a = AuditCase.find_by!(slug: "goe-2021-vending-machine-fee-miscalculation")
    a.update_columns(legal_basis: a.legal_basis.sub("공유재산 및 물품관리법,", "공유재산법,"))
    untouched = body("goe-2021-accounting-disorder-construction")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("goe-2021-accounting-disorder-construction"), "한 사례가 어긋났는데 다른 사례는 써졌다 — 전체 롤백이 아니다"
  end

  test "NEGATIVE: 적용 대상이 운영과 다르면(PUBLIC_SCHOOL·HIGH 아님) 멈춘다" do
    AuditCase.find_by!(slug: "goe-2021-contract-review-omission").update_columns(target_agency: [ "EDUCATION_SUPPORT_OFFICE" ])
    assert_raises(RuntimeError) { migrate }
  end

  test "NEGATIVE CONTROL: 목록 밖 사례의 필드는 마이그레이션 전후 동일하다" do
    others = AuditCase.where.not(slug: SLUGS).order(:id)
    assert others.where(slug: CONTROLS).count >= 5, "대조군 사례가 시드에 없다"
    before = others.map(&:attributes)
    migrate
    assert_equal before, AuditCase.where.not(slug: SLUGS).order(:id).map(&:attributes)
  end

  test "시드 원천에도 옛 문구가 남지 않는다" do
    STALE.each do |slug, list|
      seeded = FIELDS.map { |f| @expected[slug][f] }.join("\n")
      list.each { |stale| assert_not_includes seeded, stale, "#{slug}: #{stale}" }
    end
  end
end
