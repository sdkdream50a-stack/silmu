# frozen_string_literal: true

# P4 §8 (2026-09-20) — 법제처 국가법령정보 **자치법규** API fetcher.
#
# 왜 `LawApiFetcher` 를 재사용하지 않는가
#   자치법규 응답은 법령 응답과 **스키마가 다르다**(2026-09-20 실측 · 원본 = harness
#   `tasks/_archive/silmu-school-accounting-calendar-p3-0920/sources/ordin/*.xml`):
#     <LawService><자치법규기본정보>
#       <자치법규ID> <자치법규일련번호> <공포일자> <공포번호> <자치법규명>
#       <시행일자> <자치법규종류> <지자체기관명> <담당부서명>
#   법령에 있는 «법령일련번호»·«현행연혁코드»·«제개정구분명»·«소관부처명» 이 **없다**.
#   없는 필드를 있는 것처럼 매핑하면 DiffEngine 이 매번 «변경» 으로 읽는다.
#
# 조회 키는 **이름이 아니라 일련번호**다 — 17개 시·도 교육규칙의 명칭이 통일돼 있지 않아
# 이름 검색으로는 전수를 회수할 수 없다(P3 에서 범위 검색으로 겨우 모았다).
module Authority
  class OrdinApiFetcher
    FIELD_MAP = {
      ordin_id:       "자치법규ID",
      mst:            "자치법규일련번호",
      title:          "자치법규명",
      promulgated_on: "공포일자",
      revision_number: "공포번호",
      effective_on:   "시행일자",
      ordin_kind:     "자치법규종류",
      agency:         "지자체기관명",
      department:     "담당부서명"
    }.freeze

    PUBLIC_URL = "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=%s"

    def initialize(api: nil)
      @api = api
    end

    # identifier = 자치법규일련번호(문자열/정수). 반환: Authority::FetchResult
    def fetch(identifier)
      seq = identifier.to_s.strip
      return FetchResult.failure("PARSE_FAILED", "자치법규일련번호가 아닙니다: #{seq.truncate(40)}") unless seq.match?(/\A\d+\z/)

      xml = api.fetch_ordin(seq)
      return FetchResult.failure("FETCH_FAILED", "API 응답 없음 (ordinSeq=#{seq})") if xml.nil?

      node = xml.at_xpath("//자치법규기본정보")
      return FetchResult.failure("PARSE_FAILED", "자치법규기본정보 없음 (ordinSeq=#{seq})") if node.nil?

      meta = FIELD_MAP.transform_values { |tag| node.at_xpath(tag)&.text&.strip.presence }
      if meta[:title].blank? || meta[:mst].blank?
        return FetchResult.failure("PARSE_FAILED", "필수 필드 누락 (자치법규명/일련번호) — ordinSeq=#{seq}")
      end

      FetchResult.success(raw_content: canonical_payload(meta), format: :text,
                          metadata: meta, source_url: format(PUBLIC_URL, meta[:mst]))
    rescue StandardError => e
      FetchResult.failure("SOURCE_UNAVAILABLE", "#{e.class}: #{e.message}")
    end

    # 전문을 매번 받지 않고도 «개정되었는가» 는 이 조합으로 판정한다(공포일자·공포번호·시행일자).
    # 법령 fetcher 와 **같은 판정 수준**(§20 Level 1·2)이고, 없는 필드는 적지 않는다.
    def canonical_payload(meta)
      [
        "자치법규명: #{meta[:title]}",
        "자치법규ID: #{meta[:ordin_id]}",
        "자치법규종류: #{meta[:ordin_kind]}",
        "지자체기관명: #{meta[:agency]}",
        "공포일자: #{meta[:promulgated_on]}",
        "공포번호: #{meta[:revision_number]}",
        "시행일자: #{meta[:effective_on]}"
      ].join("\n")
    end

    private

    # 법령 fetcher 와 같은 이유로 **지연 생성**한다 — credentials 없는 환경(CI)에서
    # 이 클래스를 참조만 해도 죽지 않게. 실제 fetch 시점에는 종전대로 자격증명을 요구한다.
    def api = @api ||= LawApiService.new
  end
end
