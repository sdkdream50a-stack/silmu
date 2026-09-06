# R2 §1 — 공식 근거 재대조 (READ-ONLY · 법제처 공동활용 API)
# 규칙집이 인용한 조문이 **현행 원문에 실재하는지** 조문 단위로 다시 확인한다.
require "json"
svc = LawApiService.new
out = { verified_at: Time.now.utc.iso8601, documents: {} }

WANT = {
  "LOCAL_CONTRACT_ACT"    => { query: "지방자치단체를 당사자로 하는 계약에 관한 법률", articles: %w[9] },
  "LOCAL_CONTRACT_DECREE" => { query: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                               articles: %w[7 25 26 27 28 30 77] },
  "LOCAL_CONTRACT_RULE"   => { query: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙", articles: %w[33] }
}

WANT.each do |key, spec|
  res = svc.search_law(spec[:query], display: 5)
  hit = res&.xpath("//law")&.find { |n| n.at_xpath("법령명한글")&.text == spec[:query] }
  unless hit
    out[:documents][key] = { error: "법령 검색 실패" }
    next
  end
  mst = hit.at_xpath("법령일련번호")&.text
  doc = svc.fetch_law(mst)
  arts = doc.xpath("//조문단위")
  found = {}
  spec[:articles].each do |no|
    node = arts.find { |a| a.at_xpath("조문번호")&.text == no && a.at_xpath("조문제목") }
    found[no] = node.nil? ? nil : {
      title: node.at_xpath("조문제목")&.text,
      text: node.text.gsub(/[ \t]+/, " ").gsub(/\n{2,}/, "\n").strip
    }
  end
  out[:documents][key] = {
    title: hit.at_xpath("법령명한글")&.text,
    law_id: hit.at_xpath("법령ID")&.text, mst: mst,
    promulgated: hit.at_xpath("공포일자")&.text,
    effective_from: hit.at_xpath("시행일자")&.text,
    current: hit.at_xpath("현행연혁코드")&.text,
    articles: found
  }
end
puts JSON.pretty_generate(out)
