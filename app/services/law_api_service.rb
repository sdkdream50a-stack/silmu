# frozen_string_literal: true

# 법제처 국가법령정보 공동활용 API 클라이언트
# 문서: https://open.law.go.kr/LSO/openApi/guideList.do
# 인증: OC 파라미터 (법제처 등록 이메일 ID 앞부분)
class LawApiService
  BASE_URL = "http://www.law.go.kr"
  OPEN_TIMEOUT = 5   # 초
  READ_TIMEOUT  = 10 # 초

  def initialize
    @oc_id = Rails.application.credentials.dig(:law_api, :oc_id)
    raise "law_api.oc_id 미설정 — credentials 확인 필요" if @oc_id.blank?
  end

  # 법령 검색 (법령명 → 목록 반환)
  # 반환: Nokogiri::XML 또는 nil
  def search_law(query, display: 5)
    params = { OC: @oc_id, target: "law", type: "XML",
               query: query, display: display, page: 1 }
    get("/DRF/lawSearch.do", params)
  end

  # 법령 본문 전체 조회 (법령 MST 일련번호로)
  def fetch_law(mst)
    params = { OC: @oc_id, target: "law", type: "XML", MST: mst }
    get("/DRF/lawService.do", params)
  end

  # 특정 조문 조회 (MST + 조번호)
  def fetch_article(mst, article_number)
    params = { OC: @oc_id, target: "lsStmd", type: "XML",
               MST: mst, JO: "%04d0000" % article_number.to_i }
    get("/DRF/lawService.do", params)
  end

  private

  def get(path, params)
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl    = false # law.go.kr은 HTTP only
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    response = http.get(uri.request_uri)

    if response.code == "200"
      Nokogiri::XML(response.body.force_encoding("UTF-8"))
    else
      Rails.logger.warn "[LawApiService] HTTP #{response.code}: #{path} #{params}"
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "[LawApiService] 타임아웃: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "[LawApiService] 오류: #{e.class} #{e.message}"
    nil
  end
end
