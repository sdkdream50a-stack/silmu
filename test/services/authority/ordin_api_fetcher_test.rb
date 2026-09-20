# frozen_string_literal: true

require "test_helper"

# P4 §8 — 자치법규 fetcher. 외부 API 를 치지 않고 **응답 스키마 계약**만 검사한다.
class Authority::OrdinApiFetcherTest < ActiveSupport::TestCase
  XML = <<~X
    <?xml version="1.0" encoding="UTF-8"?>
    <LawService><자치법규기본정보>
      <자치법규ID>215333</자치법규ID><자치법규일련번호>1263963</자치법규일련번호>
      <공포일자>20161114</공포일자><공포번호>00939</공포번호>
      <자치법규명>서울특별시 공립학교회계 규칙</자치법규명>
      <시행일자>20161114</시행일자><자치법규종류>C0002</자치법규종류>
      <지자체기관명>서울특별시교육청</지자체기관명><담당부서명>예산담당관</담당부서명>
    </자치법규기본정보></LawService>
  X

  class FakeApi
    def initialize(xml) = @xml = xml
    attr_reader :asked
    def fetch_ordin(seq)
      @asked = seq
      @xml && Nokogiri::XML(@xml)
    end
  end

  test "일련번호로 조회하고 공개 원문 URL 을 만든다" do
    api = FakeApi.new(XML)
    r = Authority::OrdinApiFetcher.new(api: api).fetch("1263963")
    assert r.ok?
    assert_equal "1263963", api.asked
    assert_equal "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=1263963", r.source_url
    assert_equal "서울특별시 공립학교회계 규칙", r.metadata[:title]
    assert_equal "20161114", r.metadata[:effective_on]
  end

  test "이름으로 부르면 실패한다 — 규칙 명칭이 통일돼 있지 않아 이름 조회를 허용하지 않는다" do
    r = Authority::OrdinApiFetcher.new(api: FakeApi.new(XML)).fetch("서울특별시 공립학교회계 규칙")
    assert r.failed?
    assert_equal "PARSE_FAILED", r.failure_kind
  end

  test "응답 없음(장애)과 스키마 불일치(파싱)를 구분한다" do
    assert_equal "FETCH_FAILED", Authority::OrdinApiFetcher.new(api: FakeApi.new(nil)).fetch("1").failure_kind
    bad = "<?xml version=\"1.0\"?><LawService><law><법령명한글>지방계약법</법령명한글></law></LawService>"
    assert_equal "PARSE_FAILED", Authority::OrdinApiFetcher.new(api: FakeApi.new(bad)).fetch("1").failure_kind
  end

  test "필수 필드가 비면 성공으로 보지 않는다" do
    x = XML.sub("<자치법규명>서울특별시 공립학교회계 규칙</자치법규명>", "<자치법규명></자치법규명>")
    assert Authority::OrdinApiFetcher.new(api: FakeApi.new(x)).fetch("1263963").failed?
  end

  test "비교용 payload 에 법령 전용 필드를 지어내지 않는다" do
    payload = Authority::OrdinApiFetcher.new.canonical_payload(
      title: "t", ordin_id: "1", ordin_kind: "C0002", agency: "a",
      promulgated_on: "20260101", revision_number: "1", effective_on: "20260102"
    )
    %w[현행연혁 제개정구분 소관부처 법령ID].each { |f| refute_includes payload, f }
    assert_includes payload, "시행일자: 20260102"
  end

  test "공포일자·공포번호·시행일자 중 하나만 바뀌어도 payload 가 달라진다(변경 탐지 가능)" do
    base = { title: "t", ordin_id: "1", ordin_kind: "C0002", agency: "a",
             promulgated_on: "20260101", revision_number: "1", effective_on: "20260102" }
    f = Authority::OrdinApiFetcher.new
    %i[promulgated_on revision_number effective_on].each do |k|
      refute_equal f.canonical_payload(base), f.canonical_payload(base.merge(k => "9")), "#{k} 변경이 payload 에 안 보인다"
    end
  end

  test "ChangeDetector 가 ordin_api 전략을 알고, 문서는 일련번호로 조회된다" do
    src = AuthoritySource.create!(key: "o1", name: "o", source_type: "STRUCTURED_API",
                                  fetch_strategy: "ordin_api", authority_tier: 1)
    doc = AuthorityDocument.create!(key: "d1", authority_source: src, title: "서울특별시 공립학교회계 규칙",
                                    document_type: "LOCAL_RULE", official_identifier: "1263963")
    assert_equal "1263963", doc.fetch_key
    detector = Authority::ChangeDetector.new(fetchers: { "ordin_api" => Authority::OrdinApiFetcher.new(api: FakeApi.new(XML)) })
    outcome = detector.check(doc)
    assert outcome.changed?, outcome.message
    assert_equal "1263963", doc.reload.current_version.version_identifier
  end

  test "법령 문서는 종전대로 이름으로 조회된다 — 행동 불변" do
    src = AuthoritySource.create!(key: "l1", name: "l", source_type: "STRUCTURED_API",
                                  fetch_strategy: "law_api", authority_tier: 1)
    doc = AuthorityDocument.create!(key: "d2", authority_source: src, title: "지방회계법", document_type: "LAW")
    assert_equal "지방회계법", doc.fetch_key
  end

  # 독립 리뷰 R1 — 법령 문서에 일련번호가 채워져도 법령 조회는 **이름**이어야 한다.
  # 「무엇으로 찾는가」는 문서가 아니라 fetcher 를 고르는 소스가 소유한다.
  test "법령 소스는 일련번호가 있어도 이름으로 조회한다" do
    src = AuthoritySource.create!(key: "l2", name: "l", source_type: "STRUCTURED_API",
                                  fetch_strategy: "law_api", authority_tier: 1)
    doc = AuthorityDocument.create!(key: "d3", authority_source: src, title: "지방회계법",
                                    document_type: "LAW", official_identifier: "253973")
    refute src.identifier_lookup?
    assert_equal "지방회계법", doc.fetch_key
  end

  test "자치법규 소스만 일련번호 조회다" do
    src = AuthoritySource.create!(key: "o2", name: "o", source_type: "STRUCTURED_API",
                                  fetch_strategy: "ordin_api", authority_tier: 1)
    assert src.identifier_lookup?
  end
end
