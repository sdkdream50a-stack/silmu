# frozen_string_literal: true

# 2026-09-28 비도구 콘텐츠 감사 P0 — private-contract-limit-guide 법령 대조 후 검증 슬롯 채움.
# 배치8(2026-06-09)에서 «연간 누계 5천만» framing 때문에 보류했던 가이드. 본문을 건별 추정가격 기준으로 정정한 뒤
# (db/seeds/guides.rb · db/content_migrations/20260928230000_nontool_legal_content_fixes.rb) 검증일을 기록한다.
# verification_source ≤200, verification_method ≤32 가드는 배치8과 같다.

slug = "private-contract-limit-guide"
source = "법제처 — 지방계약법 시행령 §25①5호 가·나·라목·§30①2호(시행 2026.6.3.), 집행기준 예규 제372호 제5장 제3절. 동일업체 연간 누계 한도 없음(건별 추정가격 기준). 2026.8.13. 행안부 발표는 훈령 개정 미확인"
method = "law.go.kr 1:1 대조 (운영 정본 확인)"
abort "❌ source 200자 초과: #{source.length}" if source.length > 200
abort "❌ method 32자 초과: #{method.length}" if method.length > 32

g = Guide.find_by(slug: slug)
if g
  g.update_columns(verification_source: source, verification_method: method, last_verified_at: Date.new(2026, 9, 28))
  puts "✅ E-E-A-T 검증 슬롯 채움 1/1건 (2026-09-28 — #{slug})"
else
  puts "⚠️  미발견 slug: #{slug}"
end
