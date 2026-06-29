# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix(본문 authoring) 후 attest 배치23 — 단건 revenue 법령 현행화+사실정정.
#
# ⚠️ 무결성 원칙(배치6/12~22와 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/law.go.kr/위키문헌, 2026-06-29):
#   「지방세외수입금의 징수 등에 관한 법률」(2013) → 2021 「지방행정제재·부과금의 징수 등에 관한 법률」로 개칭.
#   개칭법 §2 정의: '지방세외수입'=제재·부과금 외 수수료·재산임대수입 등 포함 → 사용료·수수료 체납 징수에 적용(현행 근거법).
#   §8=독촉: 납부기한 경과 후 50일 이내 독촉장 발급, 독촉장 납부기한=발급일부터 20일 이내. §9=압류의 요건 등.
#   지방재정법 §82=금전채권과 채무의 소멸시효(5년) — lesson §3 소멸시효 근거(정합, 유지).
#
# 정정 사유(기존 오류):
#   ① 인용법 「지방세외수입금법」=개칭 전 구법명 / §19(체납처분 준용)≠독촉 근거 → 「지방행정제재·부과금법」 §8 독촉·§9 압류로 정정
#   ② 사실오류 "납기 경과 후 10일 이내 독촉장 발송"=오기(§8 독촉장 발급=50일 이내; 10일은 구법의 독촉장 납부기한, 현행 20일)
#   변경: legal_basis·lesson·checkpoints[0]. title·issue·detail·action_taken=정상 유지.

slug = "revenue-collection-delay"

NEW = {
  legal_basis: "지방행정제재·부과금의 징수 등에 관한 법률 제8조(독촉)·제9조(압류의 요건 등), 지방재정법 제82조(금전채권의 소멸시효)",
  lesson: <<~MD.strip,
    ## 실무자가 반드시 알아야 할 4가지

    ### 1. 납기 경과 후 50일 이내 독촉장 발급이 의무입니다
    지방행정제재·부과금의 징수 등에 관한 법률(구 「지방세외수입금의 징수 등에 관한 법률」) 제8조에 따라 납부기한이 지난 날부터 50일 이내에 독촉장을 발급해야 합니다. 이 절차를 생략하면 이후 체납처분의 법적 근거가 약해집니다.

    ### 2. 독촉 후에도 미납이면 체납처분을 실시해야 합니다
    독촉장에 정한 납부기한(발급일부터 20일 이내)이 지나도 납부하지 않으면 재산 조회 → 압류 → 공매 순서로 체납처분을 실시해야 합니다. 방치는 징수 포기와 같습니다.

    ### 3. 징수권 소멸시효(5년)를 반드시 관리해야 합니다
    체납 발생 후 5년이 경과하면 징수권이 소멸하여 법적으로 징수할 수 없게 됩니다(지방재정법 제82조). 체납 목록을 관리하며 소멸시효가 완성되기 전에 반드시 조치를 취해야 합니다.

    ### 4. 조기 대응이 징수 성공률을 높입니다
    체납자가 사업장을 이전하거나 재산을 처분하기 전에 빨리 조치할수록 징수 가능성이 높아집니다. 시간이 지날수록 징수는 어려워집니다.

    **체납을 방치하는 것은 공공재산을 포기하는 것과 같습니다. 즉각적인 법정 절차 이행이 최선입니다.**
  MD
  checkpoints: [
    { "icon" => "schedule", "title" => "독촉장 발급", "desc" => "납기 경과 후 50일 이내 독촉장을 발급했는지 확인" },
    { "icon" => "search", "title" => "재산 조회", "desc" => "체납자의 재산 조회를 실시했는지 확인" },
    { "icon" => "gavel", "title" => "체납처분 실시", "desc" => "독촉 후에도 미납 시 체납처분을 실시했는지 확인" },
    { "icon" => "history_edu", "title" => "소멸시효 관리", "desc" => "징수권 소멸시효(5년)를 관리하고 있는지 확인" }
  ]
}.freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 29)

a = AuditCase.find_by(slug: slug)
abort "❌ 미발견: #{slug}" if a.nil?

a.update!(NEW)
a.reload

# 잔존/정합 검산
p = []
p << "legal_basis 구법명 잔존" if a.legal_basis.include?("지방세외수입금법 제19조")
p << "legal_basis §8 누락" unless a.legal_basis.include?("제8조(독촉)")
p << "lesson 10일독촉 사실오류 잔존" if a.lesson.include?("10일 이내에 독촉장") || a.lesson.include?("10일 이내 독촉장")
p << "lesson §1 50일 미반영" unless a.lesson.include?("50일 이내에 독촉장을 발급")
p << "checkpoint 10일 잔존" if a.checkpoints.to_s.include?("10일 이내 독촉장")
p << "checkpoint 50일 미반영" unless a.checkpoints.to_s.include?("50일 이내 독촉장")
p << "소멸시효 §82 근거 소실" unless a.lesson.include?("지방재정법 제82조")

lb = a.legal_basis.to_s.strip
src_budget = 200 - prefix.length - suffix.length
lb_fit = lb.length > src_budget ? lb[0, src_budget - 1] + "…" : lb
src = "#{prefix}#{lb_fit}#{suffix}"
attested = false
if src.length <= 200
  a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
  attested = true
else
  p << "src#{src.length}>200"
end

puts "✅ content-fix(revenue 법령 현행화+50일 정정) 적용 + attest=#{attested} (배치23)"
puts "   legal_basis: #{a.legal_basis}"
puts(p.any? ? "⛔ 검산 문제: #{p.join(', ')}" : "✅ 검산 CLEAN(구법명 제거·§8 독촉·50일 반영·§82 소멸시효 보존)")
