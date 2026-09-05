# frozen_string_literal: true

require "test_helper"

# P1.55 §12·§13·§14 — LawContentFetcher 파서 회귀.
#
# 선재 결함(2026-09-06 발견): `xml.at_css("법령")` 이 실제 응답 노드 `<law>` 를 매칭하지 못해
# 항상 static 폴백으로 떨어졌고, **시행일자·소관부처·법령구분·MST 를 한 번도 받지 못했다.**
# 운영 영향: laws 15행 전부 effective_date NULL · 토픽 페이지 "(YYYY.MM.DD 시행)" 표기 0건.
class LawContentFetcherTest < ActiveSupport::TestCase
  # 2026-09-06 법제처 실제 응답
  REAL_RESPONSE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <LawSearch>
      <target>law</target><totalCnt>1</totalCnt><resultCode>00</resultCode>
      <law id="1">
        <법령일련번호>286149</법령일련번호>
        <현행연혁코드>현행</현행연혁코드>
        <법령명한글><![CDATA[지방자치단체를 당사자로 하는 계약에 관한 법률 시행령]]></법령명한글>
        <법령약칭명><![CDATA[지방계약법 시행령]]></법령약칭명>
        <공포일자>20260519</공포일자>
        <소관부처명>행정안전부</소관부처명>
        <법령구분명>대통령령</법령구분명>
        <시행일자>20260603</시행일자>
      </law>
    </LawSearch>
  XML

  EMPTY_RESPONSE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <LawSearch><target>law</target><totalCnt>0</totalCnt><resultCode>00</resultCode></LawSearch>
  XML

  setup { Rails.cache.clear }

  def meta_from(xml_string)
    fetcher = LawContentFetcher.new
    xml = xml_string.nil? ? nil : Nokogiri::XML(xml_string)
    fetcher.send(:parse_law_meta, xml, "폴백명")
  end

  test "POSITIVE — <law> 노드에서 시행일·소관부처·법령구분·MST 를 추출한다" do
    m = meta_from(REAL_RESPONSE)
    assert_not_nil m, "파싱이 실패해 폴백으로 떨어졌다 (선재 결함 재발)"
    assert_equal "286149", m[:mst]
    assert_equal "20260603", m[:effective_date]
    assert_equal "2026.06.03 시행", m[:effective_display]
    assert_equal "행정안전부", m[:ministry]
    assert_equal "대통령령", m[:law_type]
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령", m[:name]
    assert_includes m[:url], "lsiSeq=286149", "MST 기반 상세 URL 이 아니다"
  end

  test "REGRESSION — 구 셀렉터 at_css('법령') 은 이 응답을 매칭하지 못한다" do
    xml = Nokogiri::XML(REAL_RESPONSE)
    assert_nil xml.at_css("법령"),
               "픽스처 전제가 바뀌었다 — 구 셀렉터가 매칭되면 이 회귀 테스트는 무의미하다"
    assert_not_nil xml.at_xpath("//law")
  end

  test "NEGATIVE — 검색 결과 0건이면 nil 을 반환한다 (거짓 메타데이터를 만들지 않는다)" do
    assert_nil meta_from(EMPTY_RESPONSE)
  end

  test "NEGATIVE — 응답이 없으면 nil" do
    assert_nil meta_from(nil)
  end

  test "AMBIGUOUS — 시행일자 형식이 이상하면 표시 문자열을 만들지 않는다" do
    broken = REAL_RESPONSE.sub("<시행일자>20260603</시행일자>", "<시행일자>미정</시행일자>")
    m = meta_from(broken)
    assert_equal "미정", m[:effective_date]
    assert_nil m[:effective_display], "형식 불명 날짜로 '시행' 문구를 만들면 안 된다"
  end

  test "필수 필드가 비면 폴백 이름을 쓴다" do
    no_name = REAL_RESPONSE.sub(%r{<법령명한글>.*?</법령명한글>}m, "<법령명한글></법령명한글>")
    assert_equal "폴백명", meta_from(no_name)[:name]
  end
end
