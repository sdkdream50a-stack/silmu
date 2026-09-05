# frozen_string_literal: true

require "test_helper"

# P1.5 §45 — 파서는 오프라인 픽스처로 검증한다(실 API 의존 금지).
# 픽스처는 2026-09-06 실제 응답이다.
class Authority::LawApiFetcherTest < ActiveSupport::TestCase
  REAL_RESPONSE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <LawSearch>
      <target>law</target><totalCnt>1</totalCnt><resultCode>00</resultCode>
      <law id="1">
        <법령일련번호>286149</법령일련번호>
        <현행연혁코드>현행</현행연혁코드>
        <법령명한글><![CDATA[지방자치단체를 당사자로 하는 계약에 관한 법률 시행령]]></법령명한글>
        <법령약칭명><![CDATA[지방계약법 시행령]]></법령약칭명>
        <법령ID>010098</법령ID>
        <공포일자>20260519</공포일자>
        <공포번호>36338</공포번호>
        <제개정구분명>타법개정</제개정구분명>
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

  class StubApi
    def initialize(xml) = @xml = xml
    def search_law(_q, display: 1) = @xml.nil? ? nil : Nokogiri::XML(@xml)
  end

  def fetcher_for(xml) = Authority::LawApiFetcher.new(api: StubApi.new(xml))

  test "POSITIVE — 실제 응답에서 시행일·공포일·MST 를 뽑아낸다" do
    r = fetcher_for(REAL_RESPONSE).fetch("지방계약법 시행령")
    assert r.ok?
    assert_equal "286149", r.metadata[:mst]
    assert_equal "20260603", r.metadata[:effective_on]
    assert_equal "20260519", r.metadata[:promulgated_on]
    assert_equal "대통령령", r.metadata[:korean_type]
    assert_equal "지방계약법 시행령", r.metadata[:short_title]
    assert_includes r.source_url, "286149"
  end

  test "NEGATIVE — 검색 결과 0건은 PARSE_FAILED 이며 성공으로 오인되지 않는다" do
    r = fetcher_for(EMPTY_RESPONSE).fetch("존재하지않는법")
    refute r.ok?
    assert_equal "PARSE_FAILED", r.failure_kind
    assert_includes r.message, "totalCnt=0"
  end

  test "NEGATIVE — 응답 자체가 없으면 FETCH_FAILED" do
    r = fetcher_for(nil).fetch("어떤법")
    refute r.ok?
    assert_equal "FETCH_FAILED", r.failure_kind
  end

  test "REGRESSION — <law> 노드를 읽는다 (구 파서는 '법령' 을 찾아 항상 실패했다)" do
    xml = Nokogiri::XML(REAL_RESPONSE)
    assert_nil xml.at_css("법령"), "픽스처 전제가 바뀌었다"
    assert_not_nil xml.at_xpath("//law"), "실제 노드명은 <law> 다"
    assert fetcher_for(REAL_RESPONSE).fetch("x").ok?
  end

  test "canonical payload 는 비교 대상 필드를 모두 포함한다" do
    payload = fetcher_for(REAL_RESPONSE).fetch("x").raw_content
    %w[법령명 법령ID 법령구분 소관부처 공포일자 공포번호 제개정구분 시행일자 현행연혁].each do |field|
      assert_includes payload, field
    end
  end
end
