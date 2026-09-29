# frozen_string_literal: true

require "test_helper"

# 서울시교육청 사립 종합감사 공개문 대조 정정 batch S (2026-09-29) 회귀.
# 운영 모양 = 시드(정정 후)에서 edits 를 거꾸로 되돌린 상태. 마이그레이션 결과가 시드와 같아야 한다(시드·운영 동기).
class AuditTruthSTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929090000_audit_truth_s.rb")
  EDITS = eval(MIGRATION.read.split("\ncount_in = lambda").first + "\nedits") # rubocop:disable Security/Eval
  SLUGS = EDITS.map(&:first).uniq.freeze
  FIELDS = %w[issue detail lesson legal_basis checkpoints].freeze
  SEEDS = %w[sen_2024_baemyeong_audit_cases sen_2025_contracts_audit_cases sen_2025_facility_audit_cases
             sen_2025_personnel_audit_cases sen_2025_school_accounting_audit_cases
             content_enrichment_phase2_edu_etc_16_2026_05_18].freeze

  setup do
    capture_io do
      SEEDS.each { |f| load Rails.root.join("db/seeds/audit_cases/#{f}.rb") }
      load Rails.root.join("db/seeds/audit_checkpoint_backfill_2026_06_05_batch2.rb")
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

  STALE = {
    "sen-2024-school-s-academic-eval-violation" => [ "위원장: 견책", "교무부장: 견책", "모든 시·도교육청 공통", "모든 시·도교육청에 공통", "3차 이상 | 기관경고 + 학교장 경고", "위원장이 견책 이상" ],
    "sen-2024-school-s-construction-contract-violation" => [ "학교장·법인 이사장 대상 경고 수준 처분" ],
    "sen-2024-school-s-school-record-correction" => [ "자체 감사에서 적발", "교무부장: 견책", "교장: 기관통보", "3. **결재**: 담임 → 교무부장 → 교감 → 교장" ],
    "sen-2024-school-s-temp-building-unauthorized" => [ "적법화가 불가능", "사후 재신고는 받아들여지지 않습니다", "건축법 시행규칙 §13 |", "이행강제금 매년 부과", "보험 적용 불가", "시설팀장: 견책", "교장: 경고", "견책 이상으로 가중", "2024-03-26 시행본", "통보 즉시 철거" ],
    "sen-2025-school-y-school-council-online" => [ "2요건 모두 충족 시만", "비대면 절대 불가", "무효화 위험", "원칙 금지" ],
    "sen-2025-school-i-temp-teacher-screening" => [ "신규 채용과 동일", "법적으로 새 계약", "처분 강도도 높음" ],
    "sen-2025-school-s-special-leave-evidence" => [ "자녀 수 확인 없이 승인", "공무원 복무규정 §20⑭):", "통상 지방공무원 규정 준용", "## 처분\n기관주의.\n" ],
    "sen-2025-school-d-sick-leave-certificate" => [ "2025년 4월", "자체 감사", "「의료법 시행규칙」 §9에 따라 요양 기간 명시", "**요양 기간** (필수", "교무부장: 견책", "행정실장: 견책", "동반 견책 이상", "요양 기간 명시 + 의료기관 인장·서명" ],
    "sen-2025-school-d-split-private-contract" => [ "예규 제332호", "3요소 중 2개 이상", "2개 이상 일치하면 분할로 간주", "3요소 점검" ]
  }.freeze

  FRESH = {
    "sen-2024-school-s-academic-eval-violation" => [ "**기관경고** (학교 — 2019년 종합감사", "개인별 처분은 원문에 없습니다", "### 반복 지적 사례" ],
    "sen-2024-school-s-construction-contract-violation" => [ "이 건 관련자에게 \"경고\" 처분 요구", "시정 요구", "건설산업기본법 시행령 제8조 제1항", "종합공사 5천만 원 미만" ],
    "sen-2024-school-s-school-record-correction" => [ "서울특별시교육청 종합감사에서 적발", "학업성적관리위원회 심의**", "제19조②", "준영구 보관(제19조③)", "심의 생략 가능" ],
    "sen-2024-school-s-temp-building-unauthorized" => [ "허가 또는 신고 등 행정절차를 조속히 이행", "원문은 철거만 요구하지 않았습니다", "**기관주의** (학교)", "건축법 2026-02-27 시행본", "학교시설사업 촉진법 2025-11-11 시행본" ],
    "sen-2025-school-y-facility-multi-violation" => [ "1,541,000원을 교육비특별회계로 세입 조치", "관련자 \"경고\" 처분", "통신공사 1건과 전기공사 1건", "제68조(공사의 분할계약금지)", "같은 영 §68" ],
    "sen-2025-school-y-school-council-online" => [ "감염병 유행 등 불가피한 상황", "다음 2요건을 모두 충족한 경우", "서면 회의는 허용되지 않음" ],
    "sen-2025-school-i-temp-teacher-screening" => [ "동일 학교에서 **연장 계약**하는 경우에도", "결격사유는 1년 경과 시 조회", "원문 처분: 기관주의" ],
    "sen-2025-school-s-special-leave-evidence" => [ "총 21건의 가족돌봄휴가(유급)", "경조사휴가 1건", "가족돌봄휴가 3명·경조사휴가 1명", "§20⑮", "과다 지급된 급여를 회수", "사립학교법 §70의2" ],
    "sen-2025-school-d-sick-leave-certificate" => [ "2025년 10월 서울특별시교육청 종합감사", "§9①", "별도 필수 항목이 아닙니다", "실무 예시 — 원문·법령 기준 아님", "**기관주의** (학교)", "병가 사유·기간의 적정 여부를 확인한 후 승인" ],
    "sen-2025-school-d-split-private-contract" => [ "감사 당시 제324호, 현행 제372호", "감사 당시(원문) 기준", "2천만 원 초과 1억 원 이하는 소기업·소상공인", "시기 분할 점검" ]
  }.freeze

  test "되돌린 상태가 실제로 옛 문구를 담고 있다(구 코드 = 실패 조건 재현)" do
    STALE.each { |slug, list| list.each { |stale| assert_includes body(slug), stale, "#{slug}: #{stale}" } }
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
      assert_equal [ "사립학교" ], a.target_agency_labels
    end
  end

  test "POSITIVE/NEGATIVE: 새 근거 문구가 있고 틀린 법령·처분·규칙은 없다" do
    migrate
    FRESH.each { |slug, list| list.each { |fresh| assert_includes body(slug), fresh, "#{slug}: #{fresh}" } }
    STALE.each { |slug, list| list.each { |stale| assert_not_includes body(slug), stale, "#{slug}: #{stale}" } }
    # 틀린 값 대조군: 예규 번호는 원문 324·현행 372 뿐, «332» 는 어느 쪽과도 맞지 않는다
    assert_not_includes body("sen-2025-school-d-split-private-contract"), "332호"
    # 의료법 시행규칙 §9①에 없는 «요양 기간 필수»·«의료기관 인장 의무» 단정 금지
    sick = body("sen-2025-school-d-sick-leave-certificate")
    assert_no_match(/요양 기간[^\n]{0,20}(필수|의무)/, sick.gsub("별도 필수 항목", ""))
    # 원문 처분에 없는 개인 징계(견책·기관통보)가 남지 않는다
    %w[sen-2024-school-s-academic-eval-violation sen-2024-school-s-school-record-correction
       sen-2024-school-s-temp-building-unauthorized sen-2025-school-d-sick-leave-certificate].each do |slug|
      assert_no_match(/^- [^\n]*: (견책|주의|경고|기관통보) \(/, AuditCase.find_by!(slug: slug).detail, slug)
    end
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 45, EDITS.size
    assert_match(/changes=45\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| body(s) }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=45\b/, out)
    assert_match(%r{AuditCase/sen-2025-school-d-split-private-contract fields_to_change=detail,lesson,legal_basis,checkpoints}, out)
    assert_equal before, SLUGS.map { |s| body(s) }
  end

  test "NEGATIVE: 한 사례의 원문이 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    a = AuditCase.find_by!(slug: "sen-2025-school-d-split-private-contract")
    a.update_columns(legal_basis: a.legal_basis.sub("예규 제332호", "예규 제333호"))
    untouched = body("sen-2025-school-d-sick-leave-certificate")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, body("sen-2025-school-d-sick-leave-certificate"), "한 사례가 어긋났는데 다른 사례는 써졌다 — 전체 롤백이 아니다"
  end

  test "시드 원천에도 옛 문구가 남지 않는다" do
    STALE.each do |slug, list|
      seeded = FIELDS.map { |f| @expected[slug][f].to_s }.join("\n") + @expected[slug]["checkpoints"].to_json
      list.each { |stale| assert_not_includes seeded, stale, "#{slug}: #{stale}" }
    end
  end
end
