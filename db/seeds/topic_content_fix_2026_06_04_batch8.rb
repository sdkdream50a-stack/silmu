# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치8 (제N조 의미오기 감사 #3: 입찰보증금·계약보증금 조문번호)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04):
#   지방계약법 본법(253973): §12=입찰보증금 / §15=계약보증금 / §21=하자보수보증금.
#   시행령(286149): §37=입찰보증금 / §38=입찰보증금의 세입조치 / §51=계약의 이행보증(공사) /
#     §52=계약보증금 납부방법 / §53=계약보증금 면제 / §54=계약보증금의 세입조치 / §71=하자보수보증금.
#   (본법 §15: 계약보증금 일반·면제·귀속 근거, 금액·납부방법은 시행령 위임 실측 확인)
#
# 결함: bid-deposit·contract-guarantee-deposit가 입찰/계약보증금 조문번호를 다수 오인용.
#   §11=예정가격작성·§14=계약서작성·§34=입찰참가통지·§35=입찰공고시기·§37(령)=입찰보증금·
#   §38(령)=입찰보증금세입·§39(령)=입찰서제출·§48(령)=동일가격낙찰 → 보증금 조문 아님.
#
# 🛡️ 정정 매트릭스(번호 교체·설명 보존):
#   bid-deposit:
#     본법 "제11조 (입찰보증금)" → "제12조 (입찰보증금)"
#     시행령 헤더 "제34조~제37조 (입찰보증금)" → "제37조·제38조 (입찰보증금)"
#     시행령 "제34조 (입찰보증금 납부)" → "제37조 (입찰보증금 납부)"   [§37=입찰보증금]
#     시행령 "제35조 (입찰보증금 면제)" → "제37조 (입찰보증금 면제)"   [면제=§37 단서]
#     시행령 "제37조 (입찰보증금 귀속)" → "제38조 (입찰보증금 귀속)"   [§38=입찰보증금의 세입조치]
#   contract-guarantee-deposit:
#     본법 "제14조 (입찰보증금)" → "제12조 (입찰보증금)"   (§21 하자보증=§21하자보수보증금=번호정확, 무수정)
#     시행령 "제37조 (계약보증금)" → "제52조 (계약보증금)"   [§52=계약보증금 납부방법]
#     시행령 "제38조 (계약보증금 면제)" → "제53조 (계약보증금 면제)"
#     시행령 "제39조 (계약보증금 귀속)" → "제54조 (계약보증금 귀속)"   [§54=계약보증금의 세입조치]
#     시행령 "제51조 (하자보증금)" → "제71조 (하자보증금)"   [§71=하자보수보증금]
# ⛔ 보류: contract-guarantee-exemption "시행령 §48(계약보증금)" — 요율표+면제 혼재 섹션(§52/§53/본법§15 모호) → 별도 정밀판단.
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch8.rb})"'

fixes = [
  ["bid-deposit", "law_content", [
    ["지방계약법 제11조 (입찰보증금)", "지방계약법 제12조 (입찰보증금)"]
  ]],
  ["bid-deposit", "decree_content", [
    ["제34조~제37조 (입찰보증금)", "제37조·제38조 (입찰보증금)"],
    ["제34조 (입찰보증금 납부)", "제37조 (입찰보증금 납부)"],
    ["제35조 (입찰보증금 면제)", "제37조 (입찰보증금 면제)"],
    ["제37조 (입찰보증금 귀속)", "제38조 (입찰보증금 귀속)"]
  ]],
  ["contract-guarantee-deposit", "law_content", [
    ["제14조 (입찰보증금)", "제12조 (입찰보증금)"]
  ]],
  ["contract-guarantee-deposit", "decree_content", [
    ["제37조 (계약보증금)", "제52조 (계약보증금)"],
    ["제38조 (계약보증금 면제)", "제53조 (계약보증금 면제)"],
    ["제39조 (계약보증금 귀속)", "제54조 (계약보증금 귀속)"],
    ["제51조 (하자보증금)", "제71조 (하자보증금)"]
  ]]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  content = topic.public_send(field).to_s
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix batch8] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "bid-deposit" => {
    law_content: ["제11조 (입찰보증금)"],
    decree_content: ["제34조 (입찰보증금", "제35조 (입찰보증금", "제37조 (입찰보증금 귀속)"]
  },
  "contract-guarantee-deposit" => {
    law_content: ["제14조 (입찰보증금)"],
    decree_content: ["제37조 (계약보증금)", "제38조 (계약보증금 면제)", "제39조 (계약보증금 귀속)", "제51조 (하자보증금)"]
  }
}
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pats|
    pats.each do |pat|
      n = t.public_send(f).to_s.scan(pat).size
      puts "  #{slug}.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
    end
  end
end
