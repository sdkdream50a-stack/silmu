# frozen_string_literal: true

require "test_helper"

# 2026-09-28 전 도구 기능 감사 P0 — 예산 과목 도우미의 코드가 「지방자치단체 예산편성 운영기준」 별표 11 과 달랐다.
# 아래 VALID 는 별표 11 원문(law.go.kr flSeq=134501851, 2026-09-28 열람)에서 뽑은 편성목·통계목이다.
class BudgetCategoryCodesTest < ActionDispatch::IntegrationTest
  VALID = %w[
    101 101-01 101-02 101-03 101-04
    201 201-01 201-02 201-03 201-04 201-05 202 202-01 202-02 202-03 202-04 202-05
    203 203-01 203-02 203-03 203-04 204 204-01 204-02 205 206 207 207-01 207-02 207-03
    301 301-01 301-03 301-04 302 303 304 305 306 307 307-01 307-02 307-03 307-04 307-05 307-10 307-11 307-12
    308 309 310 311 401 401-01 401-02 401-03 401-04 402 403 404 405 405-01 405-02 406
    501 502 601 602 701 702 703 704 705 706 801 802
  ].freeze

  def categories
    get "/tools/budget-category-finder"
    assert_response :success
    response.body.scan(/\{ keywords: \[([^\]]*)\][^\n]*?code: "([^"]+)"/).map { |kw, code| [ kw.scan(/"([^"]+)"/).flatten, code ] }
  end

  test "모든 과목 코드가 별표 11 에 실제로 있는 번호다" do
    rows = categories
    assert_operator rows.size, :>=, 30, "과목 표를 못 읽었다 — 이 검사는 무효"
    rows.each do |kws, code|
      code.split(" / ").each do |c|
        assert_includes VALID, c, "«#{kws.first}» 의 과목 #{c} 는 별표 11 에 없다"
      end
    end
  end

  test "대표 키워드는 별표 11 의 해당 과목으로 간다" do
    by = categories.to_h { |kws, code| [ kws.first, code ] }
    assert_equal "201-02", by["전기"], "전기료는 공공운영비(201-02)"
    assert_equal "202-01", by["출장"], "국내 출장은 국내여비(202-01)"
    assert_equal "401-01", by["공사"], "공사는 시설비(401-01)"
    assert_equal "307-02", by["보조금"], "민간 보조는 민간경상사업보조(307-02)"
  end

  test "화면은 통계목까지 표시할 수 있게 «과목» 으로 적는다" do
    get "/tools/budget-category-finder"
    assert_not_includes response.body, "편성목 ${item.code}번"
  end
end
