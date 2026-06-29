# frozen_string_literal: true

# 2026-06-29 attest 배치26 — 입찰 클러스터 bid-unfair-spec (CLEAN attest, content-fix 없음).
#
# ⚠️ 무결성 원칙(배치6/12~25와 동일): 합성 콘텐츠. 정직 공시. attest=update_columns(메타전용, IndexNow 미발생).
#
# 1차출처 대조(LBOX/easylaw, 2026-06-29):
#   bid-unfair-spec(특정 업체 유리 규격): legal_basis="지방계약법 제9조, 입찰 및 계약집행기준"
#   - 지방계약법 §9=계약의 방법(일반경쟁입찰 원칙) — 특정규격으로 경쟁 차단은 일반경쟁 취지 위반, 정합
#   - 「지방자치단체 입찰 및 계약 집행기준」=규격서 작성기준(특정 상표·규격 지정 제한, 경쟁성 확보) — 직접 근거
#   ⇒ 인용 조문 정합(오기 없음) → content-fix 없이 attest만.
#
# 보류(전자조달법 조문체계 미확정): e-bidding-error·e-procurement-bypass — 전자조달법 §8=계약상대자의 전자적 공고(≠전자입찰),
#   지방계약 시행령 §38=입찰보증금의 세입조치(≠입찰방법변경)·§39=입찰서 제출·무효(≠지정정보처리장치, 정본=§6의2 정보처리장치의 지정·고시).
#   본문이 전자조달법 §8을 "전자입찰 의무"로 다수 인용 → '전자입찰 의무' 정본 조문 확정 후 별도 라운드.

slug = "bid-unfair-spec"
method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 29)

a = AuditCase.find_by(slug: slug)
abort "❌ 미발견: #{slug}" if a.nil?

lb = a.legal_basis.to_s.strip
b = 200 - prefix.length - suffix.length
lbf = lb.length > b ? lb[0, b - 1] + "…" : lb
src = "#{prefix}#{lbf}#{suffix}"
if src.length <= 200
  a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
  puts "✅ attest 1건 (배치26 — bid-unfair-spec CLEAN attest)"
  puts "   legal_basis: #{a.legal_basis}"
else
  puts "⛔ src#{src.length}>200"
end
