# frozen_string_literal: true

require "test_helper"

class LawAliasResolverTest < ActiveSupport::TestCase
  test "약칭을 정식 명칭으로 치환한다" do
    assert_equal "산업안전보건법", LawAliasResolver.resolve("산안법").canonical
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률",
                 LawAliasResolver.resolve("지방계약법").canonical
    assert_equal "국가를 당사자로 하는 계약에 관한 법률",
                 LawAliasResolver.resolve("국가계약법").canonical
    assert_equal "도시 및 주거환경정비법", LawAliasResolver.resolve("도시정비법").canonical
  end

  test "정식 명칭은 그대로 통과한다" do
    name = "지방자치단체를 당사자로 하는 계약에 관한 법률"
    assert_equal name, LawAliasResolver.resolve(name).canonical
    assert_nil LawAliasResolver.resolve(name).matched_alias
  end

  test "기본 자형 오타를 보정한다" do
    # "벚 → 법" 매핑으로 약칭 사전에 등록된 오타도 인식
    assert_equal "관세법", LawAliasResolver.resolve("관세벚").canonical
    # 등록되지 않은 오타도 자형 보정만은 적용
    assert_equal "근로기준법", LawAliasResolver.resolve("근로기준벚").canonical
  end

  test "공백·표기 차이를 흡수한다" do
    assert_equal "산업안전보건법", LawAliasResolver.resolve("산 안 법").canonical
    assert_equal "근로기준법", LawAliasResolver.resolve("근기법").canonical
  end

  test "alternatives를 함께 제공한다" do
    res = LawAliasResolver.resolve("산안법")
    assert_includes res.alternatives, "산업안전보건법 시행령"
    assert_includes res.alternatives, "산업안전보건기준에 관한 규칙"
  end

  test "미등록 법령명은 입력값을 그대로 반환한다" do
    res = LawAliasResolver.resolve("아무거나법")
    assert_equal "아무거나법", res.canonical
    assert_nil res.matched_alias
    assert_empty res.alternatives
  end

  test "관련도 점수: 정확 매칭이 부분 매칭보다 높다" do
    # 법제처 lawSearch 부분매칭 특성으로 "민법" 검색 시 "난민법"이 잡히는 케이스
    민법_score   = LawAliasResolver.relevance_score("민법", "민법 제750조")
    난민법_score = LawAliasResolver.relevance_score("난민법", "민법 제750조")

    assert 민법_score > 난민법_score,
           "민법(#{민법_score})이 난민법(#{난민법_score})보다 높아야 함"
  end

  test "관련도 점수: 시행령보다 법률 우선" do
    # 동일 법령명 prefix일 때 법률(+5)이 시행령보다 점수 우위
    law_score    = LawAliasResolver.relevance_score("관세법", "관세법")
    decree_score = LawAliasResolver.relevance_score("관세법 시행령", "관세법")

    assert law_score >= decree_score
  end
end
