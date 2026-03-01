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

  # law.go.kr WAF는 JavaScript redirect HTML을 먼저 반환함.
  # 응답 body에서 location.assign(rsu()) 패턴을 파싱해 실제 URL로 재요청.
  HEADERS = {
    "User-Agent"      => "Mozilla/5.0 (compatible; silmu-law-bot/1.0)",
    "Accept"          => "application/xml, text/xml, */*",
    "Accept-Language" => "ko-KR,ko;q=0.9",
  }.freeze

  def get(path, params)
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params)

    response = http_get(uri)
    return nil unless response

    # 302 redirect — Location 헤더를 따라감
    if response.code == "302" && response["location"].present?
      redirect_uri = URI.join(BASE_URL, response["location"])
      response = http_get(redirect_uri)
      return nil unless response
    end

    body = response.body.to_s.force_encoding("UTF-8")

    # WAF JavaScript challenge 감지: HTML 응답 내부에 rsu() redirect URL이 숨겨짐
    # 예: var x={o:'...', t:'/pbNXP/DRF/...', h:'...'}; y.location.assign(rsu())
    if body.include?("location.assign(rsu())")
      waf_uri = parse_waf_redirect(body, uri)
      if waf_uri
        response = http_get(waf_uri)
        return nil unless response
        body = response.body.to_s.force_encoding("UTF-8")
      else
        Rails.logger.warn "[LawApiService] WAF redirect 파싱 실패: #{path}"
        return nil
      end
    end

    if response.code == "200" && body.start_with?("<?xml", "<")
      Nokogiri::XML(body)
    else
      Rails.logger.warn "[LawApiService] HTTP #{response.code}: #{path}"
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "[LawApiService] 타임아웃: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "[LawApiService] 오류: #{e.class} #{e.message}"
    nil
  end

  def http_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = (uri.scheme == "https")
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http.get(uri.request_uri, HEADERS)
  rescue => e
    Rails.logger.error "[LawApiService] http_get 오류: #{e.class} #{e.message}"
    nil
  end

  # WAF JS challenge body에서 실제 API URL 추출
  # 두 가지 패턴을 처리:
  # 패턴A (신): x={o:'FULL_URL',c:1}; z=4; rsu(h)=o.substr(0,c)+o.substr(c+h)
  # 패턴B (구): x={o:'TAIL',t:'HEAD',h:'MID'}; rsu()=t+h+o
  def parse_waf_redirect(body, _original_uri)
    # 패턴A 감지: rsu(z) 사용
    if body.include?("rsu(z)")
      o = body[/\bo\s*:\s*'([^']+)'/, 1]
      c = body[/\bc\s*:\s*(\d+)/, 1]&.to_i
      z = body[/\bz\s*=\s*(\d+)/, 1]&.to_i
      if o && c && z
        real_path = o[0, c] + o[(c + z)..]
        return URI.join(BASE_URL, real_path)
      end
    end

    # 패턴B 감지: t+h+o 조합
    t = body[/\bt\s*:\s*'([^']+)'/, 1]
    h = body[/\bh\s*:\s*'([^']+)'/, 1]
    o = body[/\bo\s*:\s*'([^']+)'/, 1]
    return URI.join(BASE_URL, "#{t}#{h}#{o}") if t && h && o

    nil
  rescue URI::InvalidURIError => e
    Rails.logger.warn "[LawApiService] WAF URL 파싱 오류: #{e.message}"
    nil
  end
end
