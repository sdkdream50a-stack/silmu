# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P2 — 공공기관 표준어 검사기.
# 단어 경계 없는 부분 문자열 치환이 다른 단어 안에 우연히 포함된 문자열까지 바꿨다
# (예: "계약자료"의 "계약자" → "계약상대자료", "CHRISTMAS"의 "MAS" → "CHRIST다수공급자계약").
class StandardTermCorrectorTest < ActiveSupport::TestCase
  setup do
    StandardTerm.delete_all
    StandardTerm.create!(term_korean: "계약상대자", synonyms: [ "거래처", "계약자", "계약 상대자" ])
    StandardTerm.create!(term_korean: "다수공급자계약", synonyms: [ "MAS", "다수 공급자 계약" ])
    StandardTerm.create!(term_korean: "시방서", synonyms: [ "시방 서" ])
    StandardTerm.expire_synonym_index!
  end

  teardown do
    StandardTerm.delete_all
    StandardTerm.expire_synonym_index!
  end

  test "다른 단어에 우연히 포함된 문자열은 교정하지 않는다 — 계약자료" do
    result = StandardTermCorrector.call("계약자료를 정리했다.")
    assert_equal "계약자료를 정리했다.", result[:corrected]
    assert_empty result[:changes]
  end

  test "다른 단어에 우연히 포함된 문자열은 교정하지 않는다 — CHRISTMAS" do
    result = StandardTermCorrector.call("CHRISTMAS 행사 물품 구매")
    assert_equal "CHRISTMAS 행사 물품 구매", result[:corrected]
    assert_empty result[:changes]
  end

  test "진짜 단어 경계에서는 그대로 교정한다 — 계약자" do
    result = StandardTermCorrector.call("계약자와 거래처에 연락")
    assert_equal "계약상대자와 계약상대자에 연락", result[:corrected]
    assert_equal 2, result[:changes].size
  end

  test "사양서는 시방서로 교정하지 않는다(별개의 표준용어)" do
    result = StandardTermCorrector.call("물품 사양서를 받았다")
    assert_equal "물품 사양서를 받았다", result[:corrected]
    assert_empty result[:changes]
  end
end
