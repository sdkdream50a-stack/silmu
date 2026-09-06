# R2 — ContractMethodService 실제 출력 실측 (READ-ONLY)
require "json"
cases = [
  { t: "goods",   p: 1_500_000,   s: nil },
  { t: "goods",   p: 20_000_000,  s: nil },
  { t: "goods",   p: 30_000_000,  s: nil },          # 핵심: 일반업체 3천만원
  { t: "goods",   p: 30_000_000,  s: "women" },
  { t: "service", p: 50_000_000,  s: nil },          # 핵심: 일반업체 5천만원
  { t: "service", p: 50_000_000,  s: "women" },
  { t: "service", p: 80_000_000,  s: "women" },
  { t: "service", p: 80_000_000,  s: "cooperative" },# 협동조합 — 바목 목록에 없음
  { t: "goods",   p: 100_000_000, s: nil },
  { t: "construction_general", p: 300_000_000, s: nil },
  { t: "construction_special", p: 300_000_000, s: nil },
  { t: "goods",   p: 0,           s: nil },
  { t: "",        p: 30_000_000,  s: nil }
]
out = cases.map { |c|
  r = ContractMethodService.determine(contract_type: c[:t], estimated_price: c[:p], special_enterprise: c[:s])
  { input: c, success: r[:success],
    method: r.dig(:result, :method), detail: r.dig(:result, :method_detail),
    basis: r.dig(:result, :basis), note: r.dig(:result, :note),
    special_condition: r.dig(:result, :special_condition),
    special_applied: r.dig(:result, :special_applied),
    warn_titles: Array(r[:warnings]).map { |w| w[:title] },
    error: r[:error] }
}
puts JSON.pretty_generate({ measured_at: Time.now.utc.iso8601,
  special_enterprises: ContractMethodService.special_enterprises,
  cases: out })
