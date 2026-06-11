# frozen_string_literal: true

require "test_helper"

class SearchQueryParserTest < ActiveSupport::TestCase
  test "공백으로 토큰을 분리한다" do
    assert_equal [ [ "지방계약법" ], [ "수의계약" ] ],
                 SearchQueryParser.tokens("지방계약법 수의계약")
  end

  test "단일 토큰은 변형 배열 하나를 반환한다" do
    tokens = SearchQueryParser.tokens("검수")
    assert_equal 1, tokens.size
    assert_includes tokens.first, "검수"
  end

  test "동의어를 변형 배열에 확장한다 (원어 유지)" do
    tokens = SearchQueryParser.tokens("성과급")
    assert_includes tokens.first, "성과급"
    assert_includes tokens.first, "성과상여금"
  end

  test "동의어 매핑은 대소문자를 무시한다" do
    tokens = SearchQueryParser.tokens("MAS")
    assert_includes tokens.first, "MAS"
    assert_includes tokens.first, "다수공급자계약"
  end

  test "빈 쿼리는 빈 배열을 반환한다" do
    assert_equal [], SearchQueryParser.tokens("")
    assert_equal [], SearchQueryParser.tokens("   ")
    assert_equal [], SearchQueryParser.tokens(nil)
  end

  test "연속 공백을 흡수하여 빈 토큰을 만들지 않는다" do
    assert_equal [ [ "입찰" ], [ "공고" ] ],
                 SearchQueryParser.tokens("입찰   공고")
  end

  test "토큰 개수는 MAX_TOKENS 로 제한된다" do
    query = (1..20).map { |i| "토큰#{i}" }.join(" ")
    assert_equal SearchQueryParser::MAX_TOKENS, SearchQueryParser.tokens(query).size
  end
end
