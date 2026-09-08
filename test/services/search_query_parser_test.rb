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

  test "닫힌 관형형·연결어미 클래스를 떼어 온전한 어간을 추가한다" do
    %w[계약한 계약할 계약하는 계약했던 계약해야 계약하고 계약하면].each do |word|
      variants = SearchQueryParser.tokens(word).first
      assert_includes variants, word
      assert_includes variants, "계약", "#{word}에서 계약 어간을 만들어야 함"
      assert_not_includes variants, "계약하", "#{word}에서 불완전한 하 어간을 남기면 안 됨"
    end

    answer_tokens = SearchQueryParser.answer_tokens("계약하는")
    assert_includes answer_tokens, "계약"
    assert_not_includes answer_tokens, "계약하"
  end

  test "온보딩 자연어의 서술어·의문사는 버리고 처음인데는 처음으로 복원한다" do
    tokens = SearchQueryParser.tokens("처음 계약 업무를 맡았습니다")
    assert_not_includes tokens.flatten, "맡았습니다"

    tokens = SearchQueryParser.tokens("계약 업무 처음인데 뭘 해야 하나요")
    assert_includes tokens.flatten, "처음"
    assert_not_includes tokens.flatten, "뭘"
  end

  test "견적과 견적서는 같은 뜻의 양방향 alias다" do
    assert_includes SearchQueryParser.tokens("견적").first, "견적서"
    assert_includes SearchQueryParser.tokens("견적서").first, "견적"
  end

  test "바로 답 세부어는 질문 초점을 남기고 보조용언과 종결 표현은 버린다" do
    assert SearchQueryParser.answer_detail_token?("며칠")
    assert SearchQueryParser.answer_detail_token?("얼마")
    assert SearchQueryParser.answer_detail_token?("안에")
    assert_not SearchQueryParser.answer_detail_token?("받아야")
    assert_not SearchQueryParser.answer_detail_token?("하나요")
    assert_not SearchQueryParser.answer_detail_token?("두")
  end

  test "어미를 떼면 1글자인 어간은 MIN_STEM 규율로 기각한다" do
    variants = SearchQueryParser.tokens("일할").first
    assert_includes variants, "일할"
    assert_not_includes variants, "일"

    variants = SearchQueryParser.tokens("일하는").first
    assert_not_includes variants, "일하", "긴 어미가 기각된 뒤 짧은 조사로 재분리하면 안 됨"
  end

  test "검색 완화에서 실측 잡음과 일반 토큰을 변별 토큰으로 세지 않는다" do
    assert SearchQueryParser.relaxation_distinctive_variants?([ "견적서" ])
    assert_not SearchQueryParser.relaxation_distinctive_variants?([ "두" ])
    assert_not SearchQueryParser.relaxation_distinctive_variants?([ "세" ])
    assert_not SearchQueryParser.relaxation_distinctive_variants?([ "개" ])
    assert_not SearchQueryParser.relaxation_distinctive_variants?([ "필요" ])
  end

  test "검색 완화 잡음 목록은 길이 규칙으로 처리할 1글자 토큰을 중복 열거하지 않는다" do
    assert_equal %w[받아야 필요한], SearchQueryParser::RELAXATION_NOISE_TOKENS
  end

  # ---- P1.6 독립검증 재수리 · Answer-First 전용 프리미티브 ----

  test "generic_variants?: 일반 토큰 묶음을 구분한다" do
    assert SearchQueryParser.generic_variants?([ "지급" ])
    assert SearchQueryParser.generic_variants?([ "기준은", "기준" ]), "조사가 붙어도 일반 토큰이다"
    assert_not SearchQueryParser.generic_variants?([ "차비", "운임" ])
    assert_not SearchQueryParser.generic_variants?([ "차비", "지급" ]),
      "하나라도 고유어면 그 묶음은 distinctive 다"
  end

  test "generic_variants?: 목록을 무분별하게 넓히지 않는다" do
    # 늘어나면 바로 답이 조용히 사라진다. 늘릴 때는 이 단언을 함께 고쳐야 한다.
    assert_equal %w[기준 방법 지급 신청 처리 가능 필요].sort,
                 SearchQueryParser::GENERIC_TOKENS.sort
  end

  test "answer_tokens: 낱말 경계로 자르고 조사를 뗀 형태까지 담는다" do
    set = SearchQueryParser.answer_tokens("숙박비 지급 기준은 어떻게 되나요?")
    assert_includes set, "숙박비"
    assert_includes set, "기준은"
    assert_includes set, "기준"
  end

  test "answer_tokens: 낱말 안쪽 부분문자열은 토큰이 아니다 (주차비 ⊅ 차비)" do
    set = SearchQueryParser.answer_tokens("자가용 출장 시 통행료와 주차비도 받을 수 있나요?")
    assert_includes set, "주차비"
    assert_not_includes set, "차비", "경계 없는 부분일치가 되살아났다"
  end

  test "answer_tokens: 낱말 안에 오는 부호는 자르지 않는다 (6+6)" do
    assert_includes SearchQueryParser.answer_tokens("6+6 부모육아휴직제 상한이 적용되나요?"), "6+6"
  end

  test "answer_tokens: 빈 입력은 빈 집합" do
    assert_empty SearchQueryParser.answer_tokens(nil)
    assert_empty SearchQueryParser.answer_tokens("   ")
  end
end
