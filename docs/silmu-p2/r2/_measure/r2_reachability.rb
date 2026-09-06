# R2 — 검색 도달성 + Answer-First + 도구 실측 (READ-ONLY · 쓰기 0)
# 도구 매칭은 재구현하지 않고 운영 경로(ChatbotController#search_tools)를 그대로 호출한다.
# 양성대조: "답 없음"·"도구 0"을 보고하기 전에 이 프로브가 양성을 잡는지 먼저 증명한다.
require "json"

CTRL = ChatbotController.new
CTRL.set_request!(ActionDispatch::TestRequest.create)

def probe(q)
  topics = Topic.search_multiple(q).to_a
  ans    = Topic.answer_for(q, topics)
  tools  = CTRL.send(:search_tools, q)
  { q: q, topic_count: topics.size, topic_slugs: topics.first(5).map(&:slug),
    answer: ans.nil? ? nil : { q: (ans[:question] || ans["question"]),
                               a: (ans[:answer] || ans["answer"]).to_s[0, 140] },
    tool_count: tools.size, tool_titles: tools.map { |t| t[:title] } }
end

out = { measured_at: Time.now.utc.iso8601, mutations: 0 }
out[:positive_control] = [ "연가 일수", "병가 진단서", "여비계산", "계약방식" ].map { |q| probe(q) }
out[:r1_regression]    = [ "수의계약 한도", "수의계약한도", "소액수의", "분할발주", "분리 발주",
                           "수입인지", "보조금정산", "국외출장" ].map { |q| probe(q) }
out[:task_tests]       = [ "수의계약 한도", "3000만원 물품 수의계약 가능한가", "5000만원 용역 수의계약 가능한가",
                           "공사를 나눠 계약해도 되나", "같은 물품을 여러 번 나눠 사도 되나",
                           "분리발주와 분할발주의 차이", "처음 계약을 맡았어요" ].map { |q| probe(q) }
out[:precision_guards] = [ "차비", "숙박비 지급 기준", "지급 기준", "병가", "출장" ].map { |q| probe(q) }

helper = Class.new { include ToolsHelper; include Rails.application.routes.url_helpers }.new
reg = helper.tools_registry
out[:tools_total] = reg.size
out[:registry] = reg.map { |t| { title: t[:title], path: t[:path].to_s, keywords: t[:keywords], domain: t[:domain] } }
puts JSON.pretty_generate(out)
