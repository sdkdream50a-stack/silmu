# frozen_string_literal: true

require "test_helper"

# 서울시교육청 사립 종합감사 공개문 대조 정정 P2/P3 batch SEN (2026-09-29) 회귀.
# 운영 모양 = 시드(정정 후)에서 edits 를 거꾸로 되돌린 상태. 마이그레이션 결과가 시드와 같아야 한다(시드·운영 동기).
class AuditTruthP2p3SenTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929121000_audit_truth_p2p3_sen.rb")
  EDITS = eval(MIGRATION.read.split("\ncount_in = lambda").first + "\nedits") # rubocop:disable Security/Eval
  SLUGS = EDITS.map(&:first).uniq.freeze
  FIELDS = %w[issue detail lesson legal_basis checkpoints].freeze
  SEEDS = %w[sen_2025_contracts_audit_cases sen_2025_facility_audit_cases
             sen_2025_personnel_audit_cases sen_2025_school_accounting_audit_cases].freeze
  # 목록 밖 P0/P1 사례(같은 시드 파일) — 마이그레이션이 건드리면 안 된다.
  CONTROLS = %w[sen-2025-school-d-split-private-contract sen-2025-school-y-facility-multi-violation
                sen-2025-school-s-special-leave-evidence sen-2025-school-y-school-council-online].freeze

  setup do
    capture_io do
      SEEDS.each { |f| load Rails.root.join("db/seeds/audit_cases/#{f}.rb") }
    end
    # 운영 표시와 같게: 적용 대상 = 사립학교(HIGH). 마이그레이션은 이 값을 건드리지 않아야 한다.
    AuditCase.where(slug: SLUGS).update_all(target_agency: [ "PRIVATE_SCHOOL" ], agency_scope_confidence: "HIGH", view_count: 170)
    @expected = SLUGS.to_h do |slug|
      a = AuditCase.find_by!(slug: slug)
      [ slug, FIELDS.to_h { |f| [ f, a.read_attribute(f) ] }.merge("title" => a.title) ]
    end
    SLUGS.each do |slug|
      AuditCase.find_by!(slug: slug).update_columns(FIELDS.to_h { |f| [ f, revert(@expected[slug][f], slug, f) ] })
    end
  end

  def revert(value, slug, field)
    EDITS.select { |s, f, _, _| s == slug && f == field }.reverse.each do |_, _, old, new|
      value = value.is_a?(String) ? value.gsub(new) { old } : JSON.parse(value.to_json.gsub(new.to_json[1..-2]) { old.to_json[1..-2] })
    end
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
    (FIELDS.map { |f| a.read_attribute(f).to_s } + [ a.checkpoints.to_json ]).join("\n")
  end

  def snapshot_others
    AuditCase.where.not(slug: SLUGS).order(:slug).map { |a| a.attributes.except("updated_at") }
  end

  STALE = {
    "sen-2025-foundation-y-audit-omission" => [ "메모리 #9", "14일 이내 감사 의무", "공립학교 법인은 별도" ],
    "sen-2025-school-y-handover" => [ "11회 인계인수 누락", "공립학교 행정실도 동일" ],
    "sen-2025-school-i-split-private-disability" => [ "예규 제332호", "처분 강도 더 높음", "발주 흔적으로 분할 적발", "설계+공사는 동일 사업으로 본다는 해석" ],
    "sen-2025-school-c-development-fund-misuse" => [ "횡령 의혹" ],
    "sen-2025-school-c-electrical-separate-order" => [ "무자격으로 전기공사 시공 = §3 위반", "형사책임 직결" ],
    "sen-2025-school-c-school-council-composition" => [ "1종 누락 시 운영위 자체 무효", "심의 자체 무효", "학교회계 예결산 심의 기관" ],
    "sen-2025-school-v-budget-pre-execution" => [ "2025.3.12. 예정이었음", "2024년도(회계연도) 1월" ],
    "sen-2025-school-v-facility-split-private" => [ "§26 1~7호", "감사관이 즉시 확인", "이중 위반" ],
    "sen-2025-school-y-vehicle-leave-violation" => [ "무상 대여하면 즉시" ],
    "sen-2025-school-s-disaster-prevention" => [ "학교장 형사책임", "발주자 책임 가중" ],
    "sen-2025-school-s-service-contract-violation" => [ "9,400만 원", "§26 1~7호" ],
    "sen-2025-school-s-supply-direct-prod-cert" => [ "계약 무효화 위험" ],
    "sen-2025-school-c-long-term-contract-violation" => [ "1년분만 산정 → 입찰 공정성 훼손" ]
  }.freeze

  FRESH = {
    "sen-2025-foundation-y-audit-omission" => [ "§41②는 이 감사의 기한을 정하지 않음", "인계인수 누락과 결합되면" ],
    "sen-2025-school-y-handover" => [ "회계관계직원 10차례 미작성 + 발전기금 출납명령기관 1건 소홀" ],
    "sen-2025-school-i-split-private-disability" => [ "원문 제324호; 현행 제372호, 2026.7.1.", "관련자 \"주의\" 처분" ],
    "sen-2025-school-c-development-fund-misuse" => [ "요령 위반(목적 외·제한 항목 사용)" ],
    "sen-2025-school-c-electrical-separate-order" => [ "분리발주(법 §11①); 예외는 법 §11③·시행령 §8" ],
    "sen-2025-school-c-school-council-composition" => [ "회의·심의의 효력(무효)은 판단하지 않음", "교비회계 예·결산 심의 기관" ],
    "sen-2025-school-v-budget-pre-execution" => [ "교부 안내는 2025년 3월 예정", "실제 교부는 2025.3.12.", "2024회계연도에 속하는 2025년 1월" ],
    "sen-2025-school-v-facility-split-private" => [ "§26①각 호(현행 제1~5호)", "예정가격을 낮춰 1인 수의계약한 사실을 지적" ],
    "sen-2025-school-y-vehicle-leave-violation" => [ "본교 교비 구입 차량을 이용하게 한 사실" ],
    "sen-2025-school-s-disaster-prevention" => [ "기술지도계약 체결 의무(산안법 §73) 위반" ],
    "sen-2025-school-s-service-contract-violation" => [ "2022: 94,297,000원 거래", "§26①각 호(현행 제1~5호)" ],
    "sen-2025-school-s-supply-direct-prod-cert" => [ "+ 직접생산확인 미확인." ],
    "sen-2025-school-c-facility-design-document" => [ "같은 법 시행령 제26조·제30조·제68조(분할수의계약 지적)", "사학기관 재무·회계 규칙 제4조·제35조" ],
    "sen-2025-school-c-long-term-contract-violation" => [ "2년 총액이 아닌 1개 연도분으로 산정하는 등 관련 규정에 위배" ]
  }.freeze

  test "되돌린 상태가 실제로 옛 문구를 담고 있다(구 코드 = 실패 조건 재현)" do
    STALE.each { |slug, list| list.each { |stale| assert_includes body(slug), stale, "#{slug}: #{stale}" } }
    assert_not_includes body("sen-2025-school-c-facility-design-document"), "(분할수의계약 지적)"
  end

  test "NORMAL: 마이그레이션 결과가 정정된 시드와 같고 slug·title·view_count·target_agency 는 그대로다" do
    migrate
    SLUGS.each do |slug|
      a = AuditCase.find_by!(slug: slug)
      FIELDS.each { |f| assert_equal @expected[slug][f], a.read_attribute(f), "#{slug} #{f}" }
      assert_equal @expected[slug]["title"], a.title
      assert_equal 170, a.view_count
      assert_equal [ "PRIVATE_SCHOOL" ], a.target_agency, slug
      assert_equal "HIGH", a.agency_scope_confidence
    end
  end

  test "POSITIVE/NEGATIVE: 새 문구가 있고 원문에 없는 단정·옛 조문은 없다" do
    migrate
    FRESH.each { |slug, list| list.each { |fresh| assert_includes body(slug), fresh, "#{slug}: #{fresh}" } }
    STALE.each { |slug, list| list.each { |stale| assert_not_includes body(slug), stale, "#{slug}: #{stale}" } }
    assert_not_includes body("sen-2025-school-i-split-private-disability"), "332호"
  end

  test "NEGATIVE CONTROL: 목록 밖 사례(P0/P1 포함)는 마이그레이션 전후 모든 필드가 같다" do
    assert(CONTROLS.all? { |s| AuditCase.exists?(slug: s) })
    assert_empty CONTROLS & SLUGS
    before = snapshot_others
    migrate
    assert_equal before, snapshot_others
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 24, EDITS.size
    assert_equal 14, SLUGS.size
    assert_match(/changes=24\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=24\b/, out)
    assert_match(%r{AuditCase/sen-2025-school-i-split-private-disability fields_to_change=detail,lesson,legal_basis}, out)
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "NEGATIVE: 한 사례의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    a = AuditCase.find_by!(slug: "sen-2025-school-i-split-private-disability")
    a.update_columns(legal_basis: a.legal_basis.sub("예규 제332호", "예규 제333호"))
    untouched = body("sen-2025-foundation-y-audit-omission")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("sen-2025-foundation-y-audit-omission"), "한 사례가 어긋났는데 다른 사례는 써졌다 — 전체 롤백이 아니다"
  end

  test "시드 원천에도 옛 문구가 남지 않는다" do
    STALE.each do |slug, list|
      seeded = FIELDS.map { |f| @expected[slug][f].to_s }.join("\n") + @expected[slug]["checkpoints"].to_json
      list.each { |stale| assert_not_includes seeded, stale, "#{slug}: #{stale}" }
    end
  end
end
