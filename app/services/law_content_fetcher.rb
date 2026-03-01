# frozen_string_literal: true

# 토픽별 관련 법령 메타데이터를 법제처 API 또는 DB에서 조회하는 서비스
# 캐싱 전략: Solid Cache(7일) → DB 폴백 → nil
class LawContentFetcher
  # 토픽 slug → 관련 법령명 매핑
  # 법제처 API 검색에 사용하는 한글 법령명 (검색 키워드)
  TOPIC_LAW_MAP = {
    # 지방계약법 계열 토픽
    "private-contract"              => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "private-contract-limit"        => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "private-contract-amount"       => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "private-contract-overview"     => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "single-quote"                  => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "dual-quote"                    => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "emergency-contract"            => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "price-negotiation"             => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "bidding"                       => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "bid-announcement"              => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "estimated-price"               => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "contract-execution"            => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "contract-guarantee-deposit"    => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "inspection"                    => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "payment"                       => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "advance-payment"               => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "late-penalty"                  => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "defect-warranty"               => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "design-change"                 => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "price-escalation"              => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "contract-termination"          => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "lowest-bid-rate"               => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "bid-qualification"             => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "multiple-price"                => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
                                         rule: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙" },
    "split-contract-prohibition"    => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "contract-guarantee-exemption"  => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                         decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    "private-contract-justification" => { law: "지방자치단체를 당사자로 하는 계약에 관한 법률",
                                           decree: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령" },
    # 여비/인사 계열
    "travel-expense"                => { law: "공무원 여비 규정",
                                         decree: "공무원 여비 규정" },
    # 예산/재정 계열
    "budget-carryover"              => { law: "지방재정법",
                                         decree: "지방재정법 시행령" },
    "year-end-settlement"           => { law: "소득세법",
                                         decree: "소득세법 시행령" },
  }.freeze

  def initialize
    @api = LawApiService.new
  end

  # 토픽 slug에 대한 법령 참조 정보 조회
  # 반환: { law: {name:, url:, effective_date:, ministry:}, decree: {...}, rule: {...} }
  def fetch_for_topic(topic_slug)
    mapping = TOPIC_LAW_MAP[topic_slug]
    return {} unless mapping

    mapping.each_with_object({}) do |(type, law_name), result|
      meta = fetch_law_meta(law_name)
      result[type] = meta if meta.present?
    end
  end

  # 법령명으로 메타데이터 조회 (캐시 7일)
  def fetch_law_meta(law_name)
    cache_key = "law_api/v2/meta/#{Digest::MD5.hexdigest(law_name)}"

    Rails.cache.fetch(cache_key, expires_in: 7.days, race_condition_ttl: 30) do
      xml = @api.search_law(law_name, display: 1)
      parse_law_meta(xml, law_name) || static_law_meta(law_name)
    end
  rescue => e
    Rails.logger.warn "[LawContentFetcher] fetch_law_meta 실패 (#{law_name}): #{e.message}"
    static_law_meta(law_name)
  end

  private

  def parse_law_meta(xml, fallback_name)
    return nil unless xml

    # 검색 결과에서 첫 번째 법령 추출
    # API XML 구조: <법령목록> > <법령> 또는 직접 <법령>
    item = xml.at_css("법령")
    return nil unless item

    mst  = item.at_css("법령일련번호")&.text&.strip
    name = item.at_css("법령명한글")&.text&.strip || fallback_name
    eff  = item.at_css("시행일자")&.text&.strip
    min  = item.at_css("소관부처명")&.text&.strip
    type = item.at_css("법령구분명")&.text&.strip

    # 시행일자 포맷: YYYYMMDD → YYYY. MM. DD
    effective_display = if eff&.match?(/\A\d{8}\z/)
      "#{eff[0, 4]}.#{eff[4, 2]}.#{eff[6, 2]} 시행"
    end

    {
      mst:              mst,
      name:             name,
      law_type:         type,
      ministry:         min,
      effective_date:   eff,
      effective_display: effective_display,
      url:              law_go_kr_url(mst, name),
    }
  end

  def law_go_kr_url(mst, name)
    if mst.present?
      "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=#{mst}"
    else
      "https://www.law.go.kr/법령/#{URI.encode_www_form_component(name.gsub(' ', ''))}"
    end
  end

  # API 호출 없이 법령명 기반 정적 URL 생성 (API 실패 시 폴백)
  def static_law_meta(law_name)
    {
      name:             law_name,
      url:              "https://www.law.go.kr/법령/#{URI.encode_www_form_component(law_name.gsub(' ', ''))}",
      effective_display: nil,
    }
  end
end
