# frozen_string_literal: true

# blog_autopilot 블로그 본문의 법령·수치 정확성 검증
# RegulationVerifier의 체크리스트 + LawApiService 조문 조회를 결합
class BlogLegalVerifier
  # 인용 조문 환각 검증 — 검증 가능한 법령 (LawSyncJob TARGET_LAWS 일치)
  # 본문이 인용한 "<법령명> 제X조"의 실존 여부를 법제처 API로 교차검증.
  # 법령명을 정확히 컴파일하기 위해 약칭/정식명 모두 패턴에 포함.
  CITATION_LAW_RE = /
    (?:
      공무원\s*여비\s*규정 |
      소득세법(?:\s*시행령)? |
      지방재정법(?:\s*시행령)? |
      지방자치단체를\s*당사자로\s*하는\s*계약에\s*관한\s*법률(?:\s*시행령|\s*시행규칙)? |
      국가를\s*당사자로\s*하는\s*계약에\s*관한\s*법률(?:\s*시행령)? |
      지방계약법(?:\s*시행령|\s*시행규칙)? |
      국가계약법(?:\s*시행령)?
    )
  /x.freeze

  CITATION_RE = /
    (?<law>#{CITATION_LAW_RE.source})
    \s*제(?<art>\d+)조
    (?:의(?<sub>\d+))?
    (?:\s*제(?<para>\d+)항)?
  /x.freeze

  # 1회 verify에서 검증할 최대 인용 수 (외부 API 호출 latency 보호 — Python 15s 타임아웃)
  MAX_CITATIONS_PER_VERIFY = 3

  # 검증 기준 — 출처: regulation_verifier.rb TOOL_VERIFICATIONS + 법제처 원문
  # 형식: { pattern: Regexp, correct: "올바른 표현", source: "근거 법령" }
  AMOUNT_CHECKS = [
    # 수의계약 한도 (지방계약법 시행령 제25조)
    {
      wrong_patterns: [ /물품.{0,10}용역.{0,10}(\d+)천만원\s*이하/,
                       /용역.{0,10}물품.{0,10}(\d+)천만원\s*이하/ ],
      correct_amount: "2천만원",
      correct: "물품·용역 추정가격 2천만원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 공사 수의계약 한도 — 전문공사
    {
      wrong_patterns: [ /전문공사.{0,10}(\d)천만원\s*이하/,
                       /전문.{0,5}공사.{0,10}1억\s*이하/ ],
      correct_amount: "2억원",
      correct: "전문공사 추정가격 2억원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 공사 수의계약 한도 — 종합공사 (정답 4억원, 그 외 매칭은 false)
    # wrong_pattern은 4억이 아닌 다른 숫자 표기만 잡아야 함 — 「3억」「5억」「6억」 등
    {
      wrong_patterns: [ /종합공사.{0,10}([1-3]|[5-9])억원?\s*이하/ ],
      correct_amount: "4억원",
      correct: "종합공사 추정가격 4억원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 1인 견적 기준 (지방계약법 시행령 제30조)
    # 올바른 기준: 2천만원 이하 → 1인 견적 가능, 2백만원 이하 → 견적 생략 가능
    {
      wrong_patterns: [ /500만원\s*이하.{0,20}1인\s*견적/,
                       /오백만원\s*이하.{0,20}1인\s*견적/,
                       /1인\s*견적.{0,20}500만원\s*이하/ ],
      correct_amount: "2천만원",
      correct: "추정가격 2천만원 이하인 경우 1인 견적 가능",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항"
    },
    # 견적 생략 기준
    {
      wrong_patterns: [ /(\d+)만원\s*이하.{0,20}견적.{0,10}생략/ ],
      correct_amount: "2백만원",
      correct: "추정가격 2백만원 이하인 경우 견적서 징구 생략 가능",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항 단서"
    }
  ].freeze

  # 법령 표현 원문 대조 — 구어체 표현이 쓰였는지 검사
  EXPRESSION_CHECKS = [
    {
      wrong_patterns: [ /농어촌\s*등\s*특수\s*지역/ ],
      correct: "지역 특성상 경쟁이 성립하지 아니하는 경우",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항 단서"
    },
    {
      wrong_patterns: [ /2회\s*이상\s*유찰/ ],
      correct: "2회 이상 경쟁입찰에 부쳐도 입찰자가 없는 경우",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제2호"
    }
  ].freeze

  def initialize
    @issues = []
  end

  def verify(text)
    @issues = []

    check_amounts(text)
    check_expressions(text)
    check_citations(text)

    {
      valid: @issues.empty?,
      issue_count: @issues.size,
      issues: @issues,
      checked_at: Time.current.iso8601
    }
  end

  private

  # §25(수의계약 한도) 검증 룰에 한해 컨텍스트 게이트 적용
  # 인근 텍스트에 보증금/면제/§51 등이 있으면 §51 제1항(보증금 면제 기준) 컨텍스트라
  # §25 한도 검증을 false-positive로 처리.
  CONTEXT_EXCLUDE_FOR_25 = %w[
    보증금
    면제
    보증
    계약보증
    입찰보증
    이행보증
    제51조
    §51
    51조
    면제기준
  ].freeze

  CONTEXT_WINDOW = 250 # 매칭 위치 ±N자 안에서 exclude 키워드 검사

  def check_amounts(text)
    AMOUNT_CHECKS.each do |rule|
      rule[:wrong_patterns].each do |pattern|
        matches = text.scan(pattern)
        next if matches.empty?

        # 매칭된 금액이 올바른 기준과 다른지 확인
        matches.each do |match|
          captured = match.is_a?(Array) ? match.first : nil
          next if captured && amount_matches_correct?(captured, rule[:correct_amount])

          # 컨텍스트 게이트: §25 제1항 제1호 룰만 적용
          if rule[:source].to_s.include?("제25조 제1항 제1호")
            match_pos = text.index(pattern)
            if match_pos
              window_start = [ match_pos - CONTEXT_WINDOW, 0 ].max
              window_end   = [ match_pos + CONTEXT_WINDOW, text.length ].min
              context = text[window_start...window_end].to_s
              next if CONTEXT_EXCLUDE_FOR_25.any? { |kw| context.include?(kw) }
            end
          end

          @issues << {
            type: "wrong_amount",
            found: text[pattern] || "(패턴 매칭)",
            correct: rule[:correct],
            source: rule[:source]
          }
        end
      end
    end
  end

  def check_expressions(text)
    EXPRESSION_CHECKS.each do |rule|
      rule[:wrong_patterns].each do |pattern|
        next unless text.match?(pattern)

        @issues << {
          type: "wrong_expression",
          found: text[pattern],
          correct: rule[:correct],
          source: rule[:source]
        }
      end
    end
  end

  # 추출된 숫자가 올바른 기준금액과 일치하는지 확인
  def amount_matches_correct?(extracted, correct_amount)
    extracted_normalized = extracted.to_s.gsub(/[,\s]/, "")
    correct_normalized = correct_amount.gsub(/[,\s원만억천]/, "")

    # 단순 포함 비교 (예: "2" in "2천만원")
    correct_amount.include?(extracted_normalized)
  end

  # 인용 조문 환각 검증
  # 본문에서 "<법령명> 제X조" 패턴을 추출 → 법제처 API로 실존 여부 교차검증.
  # 존재하지 않는 조문이면 wrong_citation 이슈로 기록 (auto-replace는 비활성:
  # correct를 빈 문자열로 두어 silmu_verifier.py의 apply_corrections가 스킵).
  def check_citations(text)
    found = {}
    text.to_s.scan(CITATION_RE) do
      m = Regexp.last_match
      key = m[0].strip
      found[key] ||= { law: m[:law], art: m[:art].to_i, raw: key }
    end

    found.values.take(MAX_CITATIONS_PER_VERIFY).each do |c|
      canonical = canonical_law_name(c[:law])
      mst = mst_for(canonical)
      next if mst.blank? # 검증 불가 → 통과 (false positive 방지)

      next if article_exists?(mst, c[:art])

      @issues << {
        type: "wrong_citation",
        found: c[:raw],
        correct: "", # auto-replace 비활성 — 블로그 본문 자동 수정 부적합
        note: "법제처 현행 #{canonical}에서 제#{c[:art]}조를 찾을 수 없음",
        source: "법제처 lawService API 교차검증"
      }
    end
  rescue => e
    Rails.logger.warn "[BlogLegalVerifier] check_citations 실패: #{e.class} #{e.message}"
  end

  # 추출된 법령명 raw → canonical (시행령/시행규칙 접미사 보존)
  def canonical_law_name(raw)
    s = raw.to_s.gsub(/\s+/, " ").strip
    if s =~ /\A(.+?)\s*(시행령|시행규칙)\z/
      base = Regexp.last_match(1).strip
      suffix = Regexp.last_match(2)
      "#{LawAliasResolver.resolve(base).canonical} #{suffix}"
    else
      LawAliasResolver.resolve(s).canonical
    end
  end

  # 정식명 → MST. LawContentFetcher의 7일 캐시 위에 추가 캐시 한 겹.
  def mst_for(canonical)
    Rails.cache.fetch("blog_verify/mst/#{Digest::MD5.hexdigest(canonical)}", expires_in: 7.days) do
      meta = LawContentFetcher.new.fetch_law_meta(canonical)
      meta&.dig(:mst)
    end
  rescue => e
    Rails.logger.warn "[BlogLegalVerifier] mst_for 오류 (#{canonical}): #{e.message}"
    nil
  end

  # (mst, 조번호) 쌍의 조문 실존 여부. 7일 캐시.
  # 보수적 정책: API 오류 시 true 반환(통과) — false positive로 블로그 본문 차단 방지.
  def article_exists?(mst, n)
    Rails.cache.fetch("blog_verify/article_exists/#{mst}/#{n}", expires_in: 7.days) do
      xml = LawApiService.new.fetch_article(mst, n)
      !!(xml && xml.at_css("조문번호, 조문제목, 조문내용"))
    end
  rescue => e
    Rails.logger.warn "[BlogLegalVerifier] article_exists? 오류 (mst=#{mst}, n=#{n}): #{e.message}"
    true
  end
end
