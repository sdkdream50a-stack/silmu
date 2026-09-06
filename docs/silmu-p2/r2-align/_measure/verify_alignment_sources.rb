# R2 LEGACY SEMANTIC ALIGNMENT — 공식 근거 재대조 (READ-ONLY · 법제처 공동활용 API)
# 5건 판정에 쓰이는 조문/예규를 오늘 날짜로 다시 취득한다. DB·파일 변이 0.
require "json"
require "net/http"
require "uri"
require "nokogiri"

svc = LawApiService.new
oc  = Rails.application.credentials.dig(:law_api, :oc_id)
out = { verified_at: Time.now.utc.iso8601, documents: {}, admrul: {} }

# ── 1. 법령 조문 ────────────────────────────────────────────────
WANT = {
  "LOCAL_CONTRACT_ACT"    => { query: "지방자치단체를 당사자로 하는 계약에 관한 법률", articles: %w[9] },
  "LOCAL_CONTRACT_DECREE" => { query: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                               articles: %w[7 25 28 30 77] }
}
WANT.each do |key, spec|
  res = svc.search_law(spec[:query], display: 5)
  hit = res&.xpath("//law")&.find { |n| n.at_xpath("법령명한글")&.text == spec[:query] }
  (out[:documents][key] = { error: "법령 검색 실패" }; next) unless hit
  mst = hit.at_xpath("법령일련번호")&.text
  doc = svc.fetch_law(mst)
  arts = doc.xpath("//조문단위")
  found = {}
  spec[:articles].each do |no|
    node = arts.find { |a| a.at_xpath("조문번호")&.text == no && a.at_xpath("조문제목") }
    found[no] = node.nil? ? nil : {
      title: node.at_xpath("조문제목")&.text,
      text:  node.text.gsub(/[ \t]+/, " ").gsub(/\n{2,}/, "\n").strip
    }
  end
  out[:documents][key] = {
    title: hit.at_xpath("법령명한글")&.text, law_id: hit.at_xpath("법령ID")&.text, mst: mst,
    promulgated: hit.at_xpath("공포일자")&.text, effective_from: hit.at_xpath("시행일자")&.text,
    current: hit.at_xpath("현행연혁코드")&.text, url: "https://www.law.go.kr/DRF/lawService.do?target=law&MST=#{mst}",
    articles: found
  }
end

# ── 2. 행정규칙(예규) — 분할 일반금지 근거가 예규에 있는지 ──────────
def raw_get(path, params)
  uri = URI("https://www.law.go.kr#{path}")
  uri.query = URI.encode_www_form(params)
  3.times do
    res = Net::HTTP.get_response(uri, { "User-Agent" => "Mozilla/5.0 (compatible; silmu-law-bot/1.0)" })
    return res.body.to_s.force_encoding("UTF-8") if res.code == "200"
    return nil unless res.code.start_with?("30") && res["location"]
    uri = URI.join("https://www.law.go.kr", res["location"])
  end
  nil
end

body = raw_get("/DRF/lawSearch.do", { OC: oc, target: "admrul", type: "XML",
                                      query: "지방자치단체 입찰 및 계약 집행기준", display: 20 })
if body
  x = Nokogiri::XML(body)
  list = x.xpath("//admrul").map { |n|
    { name: n.at_xpath("행정규칙명")&.text, id: n.at_xpath("행정규칙ID")&.text,
      seq: n.at_xpath("행정규칙일련번호")&.text, kind: n.at_xpath("행정규칙종류")&.text,
      eff: n.at_xpath("시행일자")&.text, cur: n.at_xpath("현행연혁코드")&.text }
  }
  out[:admrul][:search] = list
  target = list.find { |h| h[:name].to_s.include?("지방자치단체 입찰 및 계약 집행기준") }
  if target
    detail = raw_get("/DRF/lawService.do", { OC: oc, target: "admrul", type: "XML", ID: target[:id] })
    if detail
      d = Nokogiri::XML(detail)
      text = d.text.gsub(/[ \t]+/, " ")
      out[:admrul][:target] = target
      out[:admrul][:length] = text.length
      # 분할 관련 문단만 추출
      hits = text.scan(/.{240}분할.{360}/m).first(40)
      out[:admrul][:split_excerpts] = hits
    else
      out[:admrul][:error] = "본문 취득 실패"
    end
  end
else
  out[:admrul][:error] = "행정규칙 검색 실패"
end

puts JSON.pretty_generate(out)
