# frozen_string_literal: true

require "test_helper"
require "open3"

# 실무검색 금액 안내 회귀 (2026-09-17 전수감사 P0).
# 지방계약법 시행령 §25①5호: 물품·용역 2천만원 초과는 상대방 자격(청년창업·소기업 등)이 있어야 수의계약.
# 공사 한도는 종류별(종합 4억·전문 2억·그 밖의 1.6억) — 한 값으로 안내하지 않는다.
class PriceGuidePrivateContractTest < ActionDispatch::IntegrationTest
  CASES = {
    [ "goods", 15_000_000 ] => "1인 견적 수의계약",
    [ "service", 20_000_001 ] => "상대방 자격에 따라 수의계약 가능",
    [ "goods", 100_000_000 ] => "상대방 자격에 따라 수의계약 가능",
    [ "goods", 100_000_001 ] => "경쟁입찰",
    [ "construction", 160_000_000 ] => "2인 이상 견적 수의계약",
    [ "construction", 160_000_001 ] => "공사 종류에 따라 수의계약 가능",
    [ "construction", 400_000_000 ] => "공사 종류에 따라 수의계약 가능",
    [ "construction", 400_000_001 ] => "경쟁입찰"
  }.freeze

  test "server price guide follows the rule set bands" do
    CASES.each do |(category, price), expected|
      get "/silmu-search/price", params: { category: category, price: price }
      assert_response :success
      assert_includes response.body, expected, "#{category} #{price}"
    end
  end

  test "NORMAL/BOUNDARY: search page script gives the same bands (node vm)" do
    get "/silmu-search"
    assert_response :success
    script = response.body.scan(%r{<script[^>]*>([\s\S]*?)</script>}).flatten.find { |js| js.include?("function searchByPrice") }
    assert script, "금액 안내 스크립트를 찾지 못했다"
    assert_includes script, '"goods_any":20000000'

    harness = <<~JS
      const vm = require("node:vm")
      const els = {}
      const el = (id) => (els[id] ||= { value: "", innerHTML: "", classList: { add() {}, remove() {} } })
      const sandbox = { document: { getElementById: el, addEventListener() {}, querySelectorAll: () => [] }, alert() {} }
      sandbox.window = sandbox
      vm.createContext(sandbox)
      vm.runInContext(process.env.SCRIPT, sandbox)
      const out = {}
      for (const [cat, price] of JSON.parse(process.env.CASES)) {
        el("price-category").value = cat
        el("price-input").value = String(price)
        sandbox.searchByPrice()
        out[cat + ":" + price] = (el("price-result").innerHTML.match(/<h4[^>]*>([^<]*)<\\/h4>/) || [])[1]
      }
      console.log(JSON.stringify(out))
    JS
    out, status = Open3.capture2e(
      { "SCRIPT" => script, "CASES" => CASES.keys.to_json }, "node", "-e", harness
    )
    assert status.success?, out
    got = JSON.parse(out.lines.last)
    CASES.each do |(category, price), expected|
      assert_equal expected, got["#{category}:#{price}"], "#{category} #{price}"
    end
  end
end
