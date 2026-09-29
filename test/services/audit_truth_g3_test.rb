# frozen_string_literal: true

require "test_helper"

# 감사사례 Truth Closure G3 — 경기도교육청 2021 감사사례집 재구성 사례 19건 P0·P1 정정 (2026-09-29) 회귀.
# 운영 모양 = 각 필드에 운영 문구(old)가 그대로 들어 있는 레코드. 마이그레이션 후 새 문구·적용대상·쪽수가 맞아야 하고
# 원문과 모순되던 값(가공 연도·뒤바뀐 금액·없는 조건)은 남지 않아야 한다.
class AuditTruthG3Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929110000_audit_truth_g3.rb")
  ATTRS, EDITS = eval(MIGRATION.read.split("\ncount_in = ").first + "\n[attrs, edits]") # rubocop:disable Security/Eval
  SLUGS = (ATTRS.keys + EDITS.map(&:first)).uniq.freeze
  FIELDS = %w[issue lesson detail].freeze
  TOTAL = EDITS.size + ATTRS.values.sum(&:size)

  # 원문(사례집 PDF)·현행 법령과 모순되던 값 — 마이그레이션 뒤 해당 사례에 남으면 안 된다.
  STALE = {
    "goe-2021-family-allowance-misdeclaration" => [ "모두 깨져야", "세대 분리만 되면 환수 안 됨", "인사혁신처 예규", "(p.127)" ],
    "goe-2021-fiscal-year-independence-violation" => [ "세입·세출 사무 폐쇄 | 3월 20일", "3.20은 사무 폐쇄일", "사고 사실 입증서 + 학교운영위 보고", "2024-03-28" ],
    "goe-2021-football-team-extension-contract" => [ "위탁사업의 후속 사업", "1억 원 초과 사업은 학교운영위 사전 심의", "5천만원 이하 (학술연구" ],
    "goe-2021-foreign-teacher-housing-deposit" => [ "보증금을 공유재산의 일종", "시·도 교육청별 「원어민" ],
    "goe-2021-gift-voucher-management" => [ "2024.7월", "4년 후", "7일 이내", "7일 절차", "90일 미루지", "서명 없음" ],
    "goe-2021-misc-allowance-improper" => [ "명목 4종", "회의수당·자문료·여비·강사료" ],
    "goe-2021-payment-processing-improper" => [ "30일 이내 지출결의", "100~187일" ],
    "goe-2021-performance-bonus-mispayment" => [ "30일 이상", "공로연수", "§7의3 ① 4호·7호에 따른 휴직", "(p.124)" ],
    "goe-2021-private-contract-2bid-violation" => [ "2배 상향", "가능 한도(1억원)에 들어감", "의도적 분할발주", "한도 회피 의혹 농후" ],
    "goe-2021-private-contract-s2b-mismatch" => [ "2023년 교육활동", "2024년 동일", "| 2천만원 이하 | 2천만원 이하 |", "초과 → 입찰 대상 |", "그 이상이면 입찰이 원칙" ],
    "goe-2021-public-property-occupation-violation" => [ "10년간 5필지 공유재산을 무단점유", "10년 무단점유 (5필지)", "법적으로 무효", "소급 기간**: 최대 5년" ],
    "goe-2021-reserve-fund-improper" => [ "분기 1회", "분기 비교", "결산 공시", "3중 보고", "높은 이자 선택 의무" ],
    "goe-2021-retirement-pension-mismanagement" => [ "○○초등학교 적립금: 약 111,719,310원", "△△학교", "○○초등학교의 교육공무직원 확정급여형(DB형) 퇴직연금 적립금 약 1억 1,170만원이 6년간" ],
    "goe-2021-school-facility-temp-use-permit" => [ "일시사용허가 대상이 아닙니다", "별도 사용계약서를 체결했는가", "학교운영위 보고 사항", "사용계약서 체결 대상" ],
    "goe-2021-specialized-construction-license" => [ "50만원 미만", "전구 교체", "| 일반 시설 유지관리 | 시설물유지관리업 |" ],
    "goe-2021-split-private-contracts" => [ "하나만 충족해도", "33,032", "분할 추정 3요건" ],
    "goe-2021-supplies-management-neglect" => [ "14년", "2년 주기 재물조사를 학년도 말에", "(2년 주기 의무)" ]
  }.freeze

  # 원문 인용이 있는 새 근거 문구 — 마이그레이션 뒤 있어야 한다.
  PRESENT = {
    "goe-2021-family-allowance-misdeclaration" => [ "두 요건을 모두 충족해야 부양가족이므로", "(p.128)" ],
    "goe-2021-fiscal-year-independence-violation" => [ "경기도 공립학교회계 규칙 제4조", "제19조②" ],
    "goe-2021-gift-voucher-management" => [ "20××.7월", "과오지급액(60,000원) 회수" ],
    "goe-2021-management-allowance-mispayment" => [ "관련자 경고, 관리자(교장) 주의", "일할단가를 적용하지 않고 임의의 금액" ],
    "goe-2021-overtime-allowance-mispayment" => [ "현지조치, 과다지급액 회수", "기관주의, 관련자 주의, 과다지급액 회수" ],
    "goe-2021-payment-processing-improper" => [ "담당자 경고, 관리자(행정실장) 주의", "시행령 제67조제1항" ],
    "goe-2021-private-contract-2bid-violation" => [ "현행에서도 입찰 대상" ],
    "goe-2021-private-contract-s2b-mismatch" => [ "20××년 교육활동", "시행령 §30①2 단서" ],
    "goe-2021-retirement-pension-mismanagement" => [ "○○학교 퇴직적립금: 111,719,310원 (약 6년", "○○초등학교: 약 1년 2개월" ],
    "goe-2021-specialized-construction-license" => [ "부칙 제2조·제7조", "전기공사업법 제11조제3항" ],
    "goe-2021-supplies-management-neglect" => [ "(공립) 1년마다", "(사립) 2년마다" ]
  }.freeze

  setup do
    SLUGS.each_with_index do |slug, i|
      olds = FIELDS.to_h { |f| [ f, EDITS.select { |s, fld, _, _| s == slug && fld == f }.map { |e| e[2] } ] }
      base = {
        slug: slug, title: "재구성 사례 #{i}", view_count: 7 + i, sector: :edu, org_type: :school,
        target_agency: %w[PUBLIC_SCHOOL], agency_scope_confidence: "HIGH", source_page: 90 + i
      }
      ATTRS.fetch(slug, {}).each { |field, (old, _)| base[field.to_sym] = old }
      FIELDS.each { |f| base[f.to_sym] = ([ "## 사건 개요 #{i}" ] + olds[f]).join("\n\n") + "\n" }
      AuditCase.create!(base)
    end
  end

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  def snapshot(slug)
    AuditCase.find_by!(slug: slug).attributes.slice("issue", "lesson", "detail", "target_agency", "agency_scope_confidence",
                                                     "source_page", "title", "slug", "view_count")
  end

  def text(slug)
    c = AuditCase.find_by!(slug: slug)
    FIELDS.map { |f| c.read_attribute(f).to_s }.join("\n")
  end

  test "운영 모양이 실제로 옛 문구를 담고 있다(구 상태 = 실패 조건 재현)" do
    STALE.each do |slug, stales|
      body = text(slug)
      assert stales.any? { |s| body.include?(s) }, "#{slug}: 되돌린 상태에 옛 문구가 없다 — 이 테스트는 아무것도 증명하지 못한다"
    end
    assert_equal %w[PUBLIC_SCHOOL], AuditCase.find_by!(slug: "goe-2021-supplies-management-neglect").target_agency
  end

  test "POSITIVE/NEGATIVE: 새 근거 문구가 있고 원문과 모순되던 값은 남지 않는다" do
    migrate
    PRESENT.each { |slug, needles| needles.each { |n| assert_includes text(slug), n, "#{slug}: 새 문구 누락" } }
    STALE.each { |slug, stales| stales.each { |s| assert_not_includes text(slug), s, "#{slug}: 옛 값 잔존" } }
    EDITS.each { |slug, _, _, new| assert_includes text(slug), new unless new.empty? }
  end

  test "적용대상·쪽수: 혼재 4건은 [] + LOW 로 비우고 화면에 표시하지 않으며, 쪽수는 원문 쪽으로" do
    migrate
    %w[misc-allowance-improper private-contract-s2b-mismatch reserve-fund-improper supplies-management-neglect].each do |s|
      c = AuditCase.find_by!(slug: "goe-2021-#{s}")
      assert_equal [], c.target_agency
      assert_equal "LOW", c.agency_scope_confidence
      assert_not c.show_agency_scope?
    end
    assert_equal 128, AuditCase.find_by!(slug: "goe-2021-family-allowance-misdeclaration").source_page
    assert_equal 125, AuditCase.find_by!(slug: "goe-2021-performance-bonus-mispayment").source_page
    untouched = AuditCase.find_by!(slug: "goe-2021-overtime-allowance-mispayment")
    assert_equal [ %w[PUBLIC_SCHOOL], "HIGH" ], [ untouched.target_agency, untouched.agency_scope_confidence ]
  end

  test "slug·title·view_count 는 그대로다" do
    before = SLUGS.to_h { |s| [ s, snapshot(s).slice("slug", "title", "view_count") ] }
    migrate
    SLUGS.each { |s| assert_equal before[s], snapshot(s).slice("slug", "title", "view_count") }
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_equal 113, TOTAL
    assert_match(/changes=#{TOTAL}\b/, migrate)
    after = SLUGS.map { |s| snapshot(s) }
    assert_match(/changes=0\b/, migrate)
    assert_equal after, SLUGS.map { |s| snapshot(s) }
  end

  test "LOWER_BOUND: DRY_RUN 은 세기만 하고 쓰지 않는다" do
    before = SLUGS.map { |s| snapshot(s) }
    out = migrate("DRY_RUN" => "1")
    assert_match(/DRY_RUN changes=#{TOTAL}\b/, out)
    assert_match(%r{AuditCase/goe-2021-supplies-management-neglect fields_to_change=lesson,detail,target_agency,agency_scope_confidence}, out)
    assert_equal before, SLUGS.map { |s| snapshot(s) }
  end

  test "NEGATIVE: 한 사례의 문구가 운영과 다르면 아무것도 쓰지 않고 멈춘다" do
    c = AuditCase.find_by!(slug: "goe-2021-supplies-management-neglect")
    c.update_columns(detail: c.detail.sub("약 14년간 물품관리자", "약 15년간 물품관리자"))
    untouched = snapshot("goe-2021-family-allowance-misdeclaration")
    assert_raises(RuntimeError) { migrate }
    assert_equal untouched, snapshot("goe-2021-family-allowance-misdeclaration"), "한 사례가 어긋났는데 다른 사례는 써졌다 — 전체 롤백이 아니다"
  end

  test "NEGATIVE: 적용대상이 예상 밖 값이면 덮어쓰지 않고 멈춘다" do
    AuditCase.find_by!(slug: "goe-2021-reserve-fund-improper").update_columns(target_agency: %w[PRIVATE_SCHOOL])
    assert_raises(RuntimeError) { migrate }
    assert_equal %w[PRIVATE_SCHOOL], AuditCase.find_by!(slug: "goe-2021-reserve-fund-improper").target_agency
  end

  test "시드 원천(사례 블록)에도 옛 문구가 남지 않는다" do
    files = Dir[Rails.root.join("db/seeds/**/*.rb")].to_h { |f| [ f, File.read(f) ] }
    EDITS.each do |slug, _, old, new|
      next if new.include?(old) # 덧붙임형: old 는 new 안에 남는다
      variants = [ old, old.gsub("\n") { "\n      " }.gsub("\n      \n", "\n\n") ]
      files.each do |f, body|
        start = body.index(%(slug: "#{slug}")) or next
        stop = body.index(/^\s*slug: "/, start + 1) || body.size
        block = body[start...stop]
        variants.each { |v| assert_not_includes block, v, "#{File.basename(f)} #{slug}: 옛 문구 잔존 #{old[0, 30]}" }
      end
    end
  end
end
