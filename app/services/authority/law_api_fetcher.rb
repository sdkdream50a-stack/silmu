# frozen_string_literal: true

# P1.5 §17·§18 — 법제처 국가법령정보센터(구조화 API) fetcher.
#
# ⚠️ 기존 `LawContentFetcher#parse_law_meta` 는 `xml.at_css("법령")` 을 쓰는데
#    현재 API 응답의 실제 노드는 `<law>` 다(자식만 한글 태그). 그래서 파싱이 항상 실패하고
#    static 폴백으로 떨어져 **시행일자를 한 번도 받지 못하고 있었다**(2026-09-06 실측).
#    Freshness Engine 은 시행일이 핵심이므로 올바른 파서를 여기에 둔다.
module Authority
  class LawApiFetcher
    # 검색 결과 XML 의 실제 구조 (2026-09-06 실측)
    #   <LawSearch><totalCnt>1</totalCnt>
    #     <law id="1">
    #       <법령일련번호>286149</법령일련번호> <법령명한글>…</법령명한글> <법령약칭명>…</법령약칭명>
    #       <법령ID>010098</법령ID> <공포일자>20260519</공포일자> <공포번호>36338</공포번호>
    #       <제개정구분명>타법개정</제개정구분명> <소관부처명>행정안전부</소관부처명>
    #       <법령구분명>대통령령</법령구분명> <시행일자>20260603</시행일자>
    #     </law></LawSearch>
    FIELD_MAP = {
      mst:              "법령일련번호",
      law_id:           "법령ID",
      title:            "법령명한글",
      short_title:      "법령약칭명",
      promulgated_on:   "공포일자",
      revision_number:  "공포번호",
      revision_kind:    "제개정구분명",
      agency:           "소관부처명",
      korean_type:      "법령구분명",
      effective_on:     "시행일자",
      status_code:      "현행연혁코드"
    }.freeze

    def initialize(api: nil)
      @api = api || LawApiService.new
    end

    # 반환: Authority::FetchResult
    def fetch(document_title)
      xml = @api.search_law(document_title, display: 1)
      return FetchResult.failure("FETCH_FAILED", "API 응답 없음 (#{document_title})") if xml.nil?

      node = xml.at_xpath("//law")
      if node.nil?
        total = xml.at_xpath("//totalCnt")&.text.to_s
        # 검색 결과 0건은 "가져오기 실패"가 아니라 "그런 문서가 없음"이다.
        return FetchResult.failure("PARSE_FAILED", "검색 결과 없음 (totalCnt=#{total}) — #{document_title}")
      end

      meta = extract(node)
      if meta[:title].blank? || meta[:mst].blank?
        return FetchResult.failure("PARSE_FAILED", "필수 필드 누락 (title/mst) — #{document_title}")
      end

      FetchResult.success(
        raw_content: canonical_payload(meta),
        format: :text,
        metadata: meta,
        source_url: detail_url(meta)
      )
    rescue StandardError => e
      FetchResult.failure("SOURCE_UNAVAILABLE", "#{e.class}: #{e.message}")
    end

    # 메타데이터만으로 구성한 안정적 비교 대상.
    # 법령 전문을 매번 받지 않고도 "개정 여부"는 이 조합으로 판정할 수 있다.
    # (전문 diff 는 §20 Level 3·4 로 확장 — 이번 slice 는 Level 1·2)
    def canonical_payload(meta)
      [
        "법령명: #{meta[:title]}",
        "법령ID: #{meta[:law_id]}",
        "법령구분: #{meta[:korean_type]}",
        "소관부처: #{meta[:agency]}",
        "공포일자: #{meta[:promulgated_on]}",
        "공포번호: #{meta[:revision_number]}",
        "제개정구분: #{meta[:revision_kind]}",
        "시행일자: #{meta[:effective_on]}",
        "현행연혁: #{meta[:status_code]}"
      ].join("\n")
    end

    private

    def extract(node)
      FIELD_MAP.transform_values { |tag| node.at_xpath("./#{tag}")&.text.to_s.strip.presence }
    end

    def detail_url(meta)
      return nil if meta[:mst].blank?

      "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=#{meta[:mst]}"
    end
  end
end
