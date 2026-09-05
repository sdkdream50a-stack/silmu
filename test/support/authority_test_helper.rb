# frozen_string_literal: true

# P1.5 §45 — 단위 테스트는 실시간 외부기관 사이트에 의존하지 않는다.
# 실제 응답 형태(2026-09-06 법제처 실측)를 픽스처로 고정한다.
module AuthorityTestHelper
  REAL_METADATA = {
    mst: "286149", law_id: "010098",
    title: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
    short_title: "지방계약법 시행령",
    promulgated_on: "20260519", revision_number: "36338", revision_kind: "타법개정",
    agency: "행정안전부", korean_type: "대통령령",
    effective_on: "20260603", status_code: "현행"
  }.freeze

  # 고정 응답 fetcher — 호출 횟수를 세어 idempotency 검증에도 쓴다.
  class StubFetcher
    attr_reader :calls

    def initialize(result_or_proc)
      @source = result_or_proc
      @calls = 0
    end

    def fetch(title)
      @calls += 1
      @source.respond_to?(:call) ? @source.call(title, @calls) : @source
    end
  end

  # Ruby 3 는 후행 해시를 키워드로 흡수하므로 **opts 로 받고 body_extra 만 분리한다.
  def build_success_result(**opts)
    body_extra = opts.delete(:body_extra)
    meta = REAL_METADATA.merge(opts)
    body = Authority::LawApiFetcher.new.canonical_payload(meta)
    body = "#{body}\n#{body_extra}" if body_extra
    Authority::FetchResult.success(raw_content: body, format: :text, metadata: meta,
                                   source_url: "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=#{meta[:mst]}")
  end

  def create_source(**attrs)
    AuthoritySource.create!({
      key: "test_source_#{SecureRandom.hex(4)}", name: "테스트 출처",
      source_type: "STRUCTURED_API", authority_tier: 1,
      fetch_strategy: "law_api", check_interval_hours: 24
    }.merge(attrs))
  end

  def create_document(source: nil, **attrs)
    AuthorityDocument.create!({
      authority_source: source || create_source,
      key: "test_doc_#{SecureRandom.hex(4)}",
      title: REAL_METADATA[:title], short_title: REAL_METADATA[:short_title],
      document_type: "PRESIDENTIAL_DECREE", jurisdiction: "LOCAL", region: "ALL"
    }.merge(attrs))
  end

  def detector_with(result_or_proc)
    Authority::ChangeDetector.new(fetcher: StubFetcher.new(result_or_proc))
  end
end
