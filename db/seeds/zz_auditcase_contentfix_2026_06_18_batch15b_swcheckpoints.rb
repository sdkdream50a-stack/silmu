# frozen_string_literal: true

# 2026-06-18 배치15b 보충 — software-dev-misclassified-as-goods checkpoints(jsonb) 구법명 잔존 정정.
# 배치15가 legal_basis+detail만 gsub → checkpoints(jsonb 배열)의 "소프트웨어산업 진흥법상 …" 1건 누락.
# (교훈: content-fix 시 string 컬럼뿐 아니라 jsonb 필드(checkpoints/source 등)까지 전수 스캔 — special-leave와 동형)
# 「소프트웨어산업 진흥법」(폐지) → 「소프트웨어 진흥법」(2020 전부개정). update!(IndexNow) 멱등.

OLD = "소프트웨어산업 진흥법"
NEW = "소프트웨어 진흥법"

a = AuditCase.find_by(slug: "software-dev-misclassified-as-goods")
abort "❌ software-dev-misclassified-as-goods 미발견" if a.nil?

cp = a.checkpoints
fixed_cp =
  if cp.is_a?(Array)
    cp.map { |e| e.is_a?(String) ? e.gsub(OLD, NEW) : e }
  else
    cp.to_s.gsub(OLD, NEW)
  end

changed = (fixed_cp != cp)
a.update!(checkpoints: fixed_cp) if changed

a.reload
residual = a.attributes.sum { |_k, v| (v.is_a?(String) ? v : v.to_json).scan(OLD).size }
puts "✅ 배치15b software-dev checkpoints 정정 #{changed ? 1 : 0}건"
puts(residual.zero? ? "✅ 전 필드 잔존 구법명 CLEAN" : "⛔ 잔존 #{residual}건")
