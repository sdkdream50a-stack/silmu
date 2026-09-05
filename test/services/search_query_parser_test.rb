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

  # ---- P1.6 자연어 recall (조사·어미가 AND 매칭을 0건으로 만들던 문제) ----

  test "조사·어미·의문사를 토큰에서 제거한다" do
    tokens = SearchQueryParser.tokens("병가 며칠 쓰면 진단서 내야 하나요")
    heads = tokens.map(&:first)
    assert_equal [ "병가", "진단서" ], heads
  end

  test "꼬리 물음표가 붙어도 stopword 로 인식한다" do
    tokens = SearchQueryParser.tokens("수의계약 가능한가요?")
    assert_equal [ "수의계약" ], tokens.map(&:first)
  end

  test "토큰이 전부 stopword 면 원본을 유지한다 (빈 결과 방지)" do
    tokens = SearchQueryParser.tokens("며칠 하나요")
    assert_equal 2, tokens.size
    assert_equal [ "며칠", "하나요" ], tokens.map(&:first)
  end

  test "조사를 뗀 어간을 추가 변형으로 넣는다 (원어 유지 · 순수 가산)" do
    variants = SearchQueryParser.tokens("계약을").first
    assert_includes variants, "계약을"
    assert_includes variants, "계약"
  end

  test "어간이 1자면 조사를 떼지 않는다" do
    variants = SearchQueryParser.tokens("자가").first
    assert_includes variants, "자가"
    assert_not_includes variants, "자"
  end

  test "긴 조사가 기각돼도 짧은 조사로 다시 떼지 않는다" do
    # "돈으로" → "으로" 기각(어간 "돈" 1자) 후 "로" 로 재시도하면 "돈으" 라는 쓰레기 어간이 생긴다.
    variants = SearchQueryParser.tokens("돈으로").first
    assert_not_includes variants, "돈으"
    assert_includes variants, "돈으로"
  end

  test "어간에도 동의어를 확장한다" do
    variants = SearchQueryParser.tokens("출장비는").first
    assert_includes variants, "여비"
  end
end
