# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치17b (제N조 의미오기 감사 #12 보강: subcontract interpretation + AuditCase legal_basis)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# batch17 적용 후 전 필드 재스캔: interpretation_content + 연결 AuditCase legal_basis(legal-cite 카드)에 가공 시행령§56/57/58·§18 잔존.
# 🔑 메모리 교훈(batch2): 본문 정정은 Topic 콘텐츠 + 연결 AuditCase.legal_basis 동시 정정 필수(legal-cite 카드가 본문 탭 밖에서 노출).
#   AuditCase는 시드 deploy로 자동적용 안 되므로 인라인 update!. cf. [[reference_audit_cases_seed_workflow]].
# 정본: 건산법§29=하도급제한(③재하도급·⑥통보)·§34=하도급대금 지급(15일)·§35=직접지급 / 하도급법§4=부당대금결정금지·§14=직접지급.
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "eval(Base64.decode64(...))"'

# 1) interpretation_content
t = Topic.find_by(slug: "subcontract")
if t
  c = t.interpretation_content.to_s
  pairs = [
    ["- 근거: 시행령 제57조, 건설산업기본법 제29조", "- 근거: 건설산업기본법 제29조"],
    ["- 근거: 시행령 제56조, 제57조", "- 근거: 건설산업기본법 제29조"],
    ["- 근거: 시행령 제58조, 하도급법 제14조", "- 근거: 건설산업기본법 제35조, 하도급법 제14조"],
    ["- 근거: 시행령 제57조, 공동계약운용요령", "- 근거: 건설산업기본법 제29조, 공동계약운용요령"]
  ]
  m = pairs.map { |o, n| c.include?(o) ? (c = c.gsub(o, n); "OK") : "MISS" }
  t.update!(interpretation_content: c)
  puts "interpretation_content [#{m.join(',')}]"
end

# 2) AuditCase legal_basis (legal-cite 카드)
ac_fixes = {
  22 => ["지방계약법 제18조, 건설산업기본법 제29조", "건설산업기본법 제29조(일괄하도급 금지)"],
  50 => ["하도급법 제4조, 지방계약법 시행령 제56조", "하도급법 제4조(부당한 하도급대금 결정 금지)"],
  51 => ["건설산업기본법 제29조, 지방계약법 시행령 제56조", "건설산업기본법 제29조(재하도급 제한)"],
  23 => ["지방계약법 시행령 제56조", "건설산업기본법 제29조 제6항(하도급 통보)"],
  52 => ["하도급법 제13조, 지방계약법 시행령 제58조", "건설산업기본법 제34조(하도급대금 지급)"],
  24 => ["지방계약법 시행령 제58조, 하도급법 제14조", "건설산업기본법 제35조, 하도급법 제14조"]
}
ac_fixes.each do |id, (old_s, new_s)|
  a = AuditCase.find_by(id: id)
  unless a
    puts "AC##{id} NOT_FOUND"; next
  end
  if a.legal_basis.to_s == old_s
    a.update!(legal_basis: new_s); puts "AC##{id} OK -> #{new_s}"
  elsif a.legal_basis.to_s.include?(old_s)
    a.update!(legal_basis: a.legal_basis.gsub(old_s, new_s)); puts "AC##{id} OK(partial) -> #{a.legal_basis}"
  else
    puts "AC##{id} MISS (current: #{a.legal_basis})"
  end
end

puts "--- 잔존 전수 재스캔 (subcontract Topic 전 필드 + 연결 AuditCase) ---"
t = Topic.find_by(slug: "subcontract")
pats = ["지방계약법 제18조", "제18조 (하도급", "시행령 제56조", "시행령 제57조", "시행령 제58조"]
total = 0
# audit_cases 컬럼=연결 사례 존재 시 미렌더 레거시 fallback(show.html.erb:611) → 별도 보고
t.attributes.each do |col, v|
  next if v.nil?; s = v.is_a?(String) ? v : v.to_json
  pats.each do |p|
    n = s.scan(p).size
    next if n.zero?
    if col == "audit_cases"
      puts "  (legacy 미렌더 컬럼) Topic.audit_cases '#{p}'=#{n}"
    else
      puts "  RESIDUAL Topic.#{col} '#{p}'=#{n}"; total += n
    end
  end
end
[22, 50, 51, 23, 52, 24].each do |id|
  a = AuditCase.find_by(id: id); next unless a
  pats.each { |p| n = a.legal_basis.to_s.scan(p).size; (puts "  RESIDUAL AC##{id}.legal_basis '#{p}'=#{n}"; total += n) if n > 0 }
end
puts(total.zero? ? "  ✅ subcontract 가공 하도급 조문 전 필드+AuditCase CLEAN" : "  ⚠️ 잔존 #{total}")
