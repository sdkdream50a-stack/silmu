# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치16b (제N조 의미오기 감사 #11 보강: 수의계약 클러스터 regulation_content·howto_steps)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# batch16 적용 후 전 필드 스캔 결과, worklist 미포함 필드(regulation_content·howto_steps)에 동일 오기 잔존 발견.
# 정본: 시행규칙 §28=삭제 · §30=긴급재해복구 수의대상 · §39=입찰서류 작성승낙. 예정가격 작성 생략=시행령§8②,
#   계약보증금 면제=시행령§53, 수의계약 견적 절차=시행령§30, 수의계약 사유=시행령§25.
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "eval(Base64.decode64(...))"'

fixes = [
  [ "single-quote", "regulation_content", [
    [ "시행령 제25조·제30조, 시행규칙 제28조·제30조, 행정안전부 예규 제5장 제69조", "시행령 제25조·제30조, 「지방자치단체 입찰 및 계약집행기준」 제5장 제69조" ]
  ] ],
  [ "small-amount-contract", "regulation_content", [
    [ "추정가격 2천만원 이하 시 (시행규칙 제30조)", "추정가격 2천만원 이하 시 (시행령 제8조 제2항)" ],
    [ "계약금액 3천만원 이하 (시행규칙 제39조)", "계약금액 일정액 이하 (시행령 제53조)" ],
    [ "※ 관련 법령: 지방계약법 시행령 제25조, 시행규칙 제28조·제30조·제39조, 행정안전부 예규 제5장", "※ 관련 법령: 지방계약법 시행령 제25조·제30조·제53조·제8조, 행정안전부 예규 제5장" ]
  ] ],
  [ "private-contract-amount", "regulation_content", [
    [ "시행령 제7조·제25조·제30조, 시행규칙 제28조·제30조, 행정안전부 예규 제5장", "시행령 제7조·제25조·제30조, 행정안전부 예규 제5장" ]
  ] ],
  [ "private-contract-justification", "howto_steps", [
    [ "§25 (수의계약 대상)", "§25 (수의계약에 의할 수 있는 경우)" ]
  ] ]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  raw = topic.public_send(field)
  is_str = raw.is_a?(String)
  content = is_str ? raw.to_s : raw.to_json
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  new_val = is_str ? content : JSON.parse(content)
  topic.update!(field => new_val)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix batch16b] #{results.join(' | ')}"

puts "--- 잔존 전수 재스캔 (수의계약 클러스터 전 필드) ---"
patterns = [ "시행규칙 제28조", "시행규칙 제39조", "시행규칙 제30조", "제9조 (수의계약)", "시행령 제30조 제2항", "수의계약 대상)" ]
slugs = %w[private-contract private-contract-justification single-quote small-amount-contract private-contract-amount]
total = 0
slugs.each do |slug|
  t = Topic.find_by(slug: slug); next unless t
  t.attributes.each do |col, val|
    next if val.nil?
    s = val.is_a?(String) ? val : val.to_json
    patterns.each do |p|
      n = s.scan(p).size
      if n > 0
        puts "  RESIDUAL #{slug}.#{col} :: '#{p}' = #{n}"; total += n
      end
    end
  end
end
puts (total.zero? ? "  ✅ 전 필드 CLEAN (단, private-contract-amount 금액드리프트는 별도 패스 보류)" : "  ⚠️ 잔존 #{total}건")
