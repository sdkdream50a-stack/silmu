# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치12 (제N조 의미오기 감사 #7: 단가계약·계약이행보증·예정가격·계약방법·정의)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04, 지방계약법 본법253973·시행령286149):
#   본법 §2=적용 범위·§9=계약의 방법·§11=예정가격의 작성·§15=계약보증금·§22=물가변동등 조정·
#     §25=단가계약·§26=제3자를 위한 단가계약.
#   시행령 §2=정의·§8=예정가격의 작성 및 비치·§33=입찰공고·§50=계약서 작성의 생략·§51=계약의 이행보증·
#     §52=계약보증금 납부방법·§53=계약보증금 면제·§54=계약보증금의 세입조치·§69=담보책임의 존속기간·
#     §70=하자 검사·§71=하자보수보증금·§79=단가계약·§80=제3자를 위한 단가계약.
#
# 🛡️ 정정 매트릭스(번호 교체·설명 보존):
#   unit-price-contract: 본법 §22(단가계약)→§25 / 시행령 §69~§71→§79·§80(범위)·§69(단가계약체결)→§79·§70(이행요청)→§80
#   performance-guarantee: 본법 §12(계약보증금)→§15 / 시행령 §50~§53→§52~§54(범위)·§50(납부)→§52·§51(면제)→§53·§52(귀속)→§54
#   multiple-price: 본법 §10(예정가격)→§11 / 시행령 §33(예정가격작성)→§8
#   lowest-bid-rate: 본법 §12(계약의 방법 및 절차)→§9
#   goods-vs-service-contract: 본법 §2(정의)→시행령 §2(정의)  (시행령 §2(용역의 범위)=§2정의, 번호정확 무수정)
# ⛔ 보류: unit-price §70 잔여·bid-qualification(적격심사=시행령§42②+예규)·long-term-contract(§78 장기계속/계속비 단일조 중복)·
#   contract-execution.decree(§65계약변경·§67해제해지)·contract-guarantee-exemption §48(요율+면제 혼재)·lowest-bid-rate 시행령§7(낙찰하한율=예규/고시).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch12.rb})"'

fixes = [
  ["unit-price-contract", "law_content", [
    ["지방계약법 제22조 (단가계약)", "지방계약법 제25조 (단가계약)"],
    ["지방계약법 시행령 제69조~제71조", "지방계약법 시행령 제79조·제80조"]
  ]],
  ["unit-price-contract", "decree_content", [
    ["지방계약법 시행령 제69조~제71조", "지방계약법 시행령 제79조·제80조"],
    ["지방계약법 시행령 제69조 (단가계약 체결)", "지방계약법 시행령 제79조 (단가계약 체결)"],
    ["지방계약법 시행령 제70조 (이행 요청)", "지방계약법 시행령 제80조 (이행 요청)"]
  ]],
  ["performance-guarantee", "law_content", [
    ["지방계약법 제12조 (계약보증금)", "지방계약법 제15조 (계약보증금)"],
    ["지방계약법 시행령 제50조~제53조", "지방계약법 시행령 제52조~제54조"]
  ]],
  ["performance-guarantee", "decree_content", [
    ["지방계약법 시행령 제50조~제53조", "지방계약법 시행령 제52조~제54조"],
    ["지방계약법 시행령 제50조 (계약보증금 납부)", "지방계약법 시행령 제52조 (계약보증금 납부)"],
    ["지방계약법 시행령 제51조 (계약보증금 면제)", "지방계약법 시행령 제53조 (계약보증금 면제)"],
    ["지방계약법 시행령 제52조 (보증금 귀속)", "지방계약법 시행령 제54조 (보증금 귀속)"]
  ]],
  ["multiple-price", "law_content", [
    ["지방계약법 제10조 (예정가격)", "지방계약법 제11조 (예정가격)"],
    ["시행령 제33조, 예정가격 작성기준", "시행령 제8조, 예정가격 작성기준"]
  ]],
  ["multiple-price", "decree_content", [
    ["시행령 제33조 (예정가격 작성)", "시행령 제8조 (예정가격의 작성 및 비치)"],
    ["**지방계약법 시행령 제33조**", "**지방계약법 시행령 제8조**"]
  ]],
  ["lowest-bid-rate", "law_content", [
    ["지방계약법 제12조 (계약의 방법 및 절차)", "지방계약법 제9조 (계약의 방법 및 절차)"]
  ]],
  ["goods-vs-service-contract", "law_content", [
    ["## 지방계약법 제2조 (정의)", "## 지방계약법 시행령 제2조 (정의)"]
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
puts "[content_fix batch12] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "unit-price-contract" => { law_content: ["제22조 (단가계약)"], decree_content: ["제69조 (단가계약 체결)", "제70조 (이행 요청)", "제69조~제71조"] },
  "performance-guarantee" => { law_content: ["제12조 (계약보증금)"], decree_content: ["제50조 (계약보증금 납부)", "제51조 (계약보증금 면제)", "제52조 (보증금 귀속)"] },
  "multiple-price" => { law_content: ["제10조 (예정가격)"], decree_content: ["시행령 제33조 (예정가격 작성)", "**지방계약법 시행령 제33조**"] },
  "lowest-bid-rate" => { law_content: ["제12조 (계약의 방법 및 절차)"] },
  "goods-vs-service-contract" => { law_content: ["## 지방계약법 제2조 (정의)"] }
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
