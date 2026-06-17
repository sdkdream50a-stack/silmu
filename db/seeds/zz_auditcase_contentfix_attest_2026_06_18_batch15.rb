# frozen_string_literal: true

# 2026-06-18 E-E-A-T content-fix 후 attest 배치15 (S4 색인 회복) — AuditCase 조문/법령명 오기 정정.
#
# ⚠️ 무결성 원칙(배치6/12/13/14와 동일): 합성 콘텐츠(특정 실사례 아님). 정직 공시.
# content-fix = update!(콜백/IndexNow 트리거). attest = update_columns(메타 전용).
#
# 1차출처 대조로 확정한 정정 근거(LBOX 법령 뷰어 2026-06-18):
#   지방계약법 시행령 §64=검사(법 제17조제1항에 따른 검사, §64①=완료통지 14일 이내) / §65=검사조서의 작성 생략.
#     → 시행령 §53(=계약보증금 면제 영역)을 "검사"로 인용한 검수/검사 클러스터 5건은 조문번호 오기.
#   「소프트웨어산업 진흥법」=폐지·전부개정 → 「소프트웨어 진흥법」(2020.12 시행). §2제3호=소프트웨어사업 정의(현행 유지).
#
# 정정 맵:
#   [§53→§64] completion-inspection-violation · defective-inspection · goods-inspection-failure ·
#             inspection-procedure-omission · inspector-qualification-violation
#             (legal_basis "시행령 제53조" + issue 본문 "시행령 제53조는" 동시 정정)
#   [구법명]  software-dev-misclassified-as-goods: "소프트웨어산업 진흥법" → "소프트웨어 진흥법"
#             (legal_basis + detail 동시 정정. 표준어 "소프트웨어산업"(과)는 불변 — 법령명 토큰만 치환)
#
# 보류(별도 sub-batch, 추가 검증 필요): payment-advance-misuse(법§15=계약보증금이라 단순치환 불가·시행령§59 미확정) ·
#   completion-payment-checklist-001(§58→§64) · goods-selection-committee-bypassed(법§6 제목) · private-contract-retroactive(§13/§49)

INSPECTION_SLUGS = %w[
  completion-inspection-violation
  defective-inspection
  goods-inspection-failure
  inspection-procedure-omission
  inspector-qualification-violation
].freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 18)

def attest_source(a, prefix, suffix)
  lb = a.legal_basis.to_s.strip
  budget = 200 - prefix.length - suffix.length
  lb_fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
  "#{prefix}#{lb_fit}#{suffix}"
end

fixed = 0
attested = 0
missing = []
residual = []

# 1) 검수/검사 클러스터: 시행령 §53 → §64 (legal_basis + issue)
INSPECTION_SLUGS.each do |slug|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    missing << slug; next
  end
  new_lb  = a.legal_basis.to_s.gsub("시행령 제53조", "시행령 제64조")
  new_iss = a.issue.to_s.gsub("시행령 제53조", "시행령 제64조")
  changed = (new_lb != a.legal_basis.to_s) || (new_iss != a.issue.to_s)
  a.update!(legal_basis: new_lb, issue: new_iss) if changed
  fixed += 1 if changed
  residual << "#{slug}(LB)" if a.reload.legal_basis.to_s.include?("시행령 제53조")
  residual << "#{slug}(issue)" if a.issue.to_s.include?("시행령 제53조")
  src = attest_source(a, prefix, suffix)
  if src.length <= 200
    a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
    attested += 1
  else
    residual << "#{slug}(src#{src.length})"
  end
end

# 2) software-dev: 구법명 정정 (legal_basis + detail)
sw = AuditCase.find_by(slug: "software-dev-misclassified-as-goods")
if sw.nil?
  missing << "software-dev-misclassified-as-goods"
else
  new_lb  = sw.legal_basis.to_s.gsub("소프트웨어산업 진흥법", "소프트웨어 진흥법")
  new_det = sw.detail.to_s.gsub("소프트웨어산업 진흥법", "소프트웨어 진흥법")
  changed = (new_lb != sw.legal_basis.to_s) || (new_det != sw.detail.to_s)
  sw.update!(legal_basis: new_lb, detail: new_det) if changed
  fixed += 1 if changed
  sw.reload
  residual << "software-dev(LB폐지법명)" if sw.legal_basis.to_s.include?("소프트웨어산업 진흥법")
  residual << "software-dev(detail폐지법명)" if sw.detail.to_s.include?("소프트웨어산업 진흥법")
  src = attest_source(sw, prefix, suffix)
  if src.length <= 200
    sw.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
    attested += 1
  else
    residual << "software-dev(src#{src.length})"
  end
end

puts "✅ content-fix #{fixed}건 + attest #{attested}건 (2026-06-18 배치15 — §53→§64 검사 5건 + 소프트웨어 진흥법 1건)"
puts "⚠️  미발견: #{missing.join(', ')}" if missing.any?
puts(residual.any? ? "⛔ 잔존오기: #{residual.join(', ')}" : "✅ 잔존오기 CLEAN")
