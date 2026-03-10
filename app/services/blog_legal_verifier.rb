# frozen_string_literal: true

# blog_autopilot 블로그 본문의 법령·수치 정확성 검증
# RegulationVerifier의 체크리스트 + LawApiService 조문 조회를 결합
class BlogLegalVerifier
  # 검증 기준 — 출처: regulation_verifier.rb TOOL_VERIFICATIONS + 법제처 원문
  # 형식: { pattern: Regexp, correct: "올바른 표현", source: "근거 법령" }
  AMOUNT_CHECKS = [
    # 수의계약 한도 (지방계약법 시행령 제25조)
    {
      wrong_patterns: [/물품.{0,10}용역.{0,10}(\d+)천만원\s*이하/,
                       /용역.{0,10}물품.{0,10}(\d+)천만원\s*이하/],
      correct_amount: "2천만원",
      correct: "물품·용역 추정가격 2천만원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 공사 수의계약 한도 — 전문공사
    {
      wrong_patterns: [/전문공사.{0,10}(\d)천만원\s*이하/,
                       /전문.{0,5}공사.{0,10}1억\s*이하/],
      correct_amount: "2억원",
      correct: "전문공사 추정가격 2억원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 공사 수의계약 한도 — 종합공사
    {
      wrong_patterns: [/종합공사.{0,10}[^2]억원?\s*이하/],
      correct_amount: "4억원",
      correct: "종합공사 추정가격 4억원 이하",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제1호"
    },
    # 1인 견적 기준 (지방계약법 시행령 제30조)
    # 올바른 기준: 2천만원 이하 → 1인 견적 가능, 2백만원 이하 → 견적 생략 가능
    {
      wrong_patterns: [/500만원\s*이하.{0,20}1인\s*견적/,
                       /오백만원\s*이하.{0,20}1인\s*견적/,
                       /1인\s*견적.{0,20}500만원\s*이하/],
      correct_amount: "2천만원",
      correct: "추정가격 2천만원 이하인 경우 1인 견적 가능",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항"
    },
    # 견적 생략 기준
    {
      wrong_patterns: [/(\d+)만원\s*이하.{0,20}견적.{0,10}생략/],
      correct_amount: "2백만원",
      correct: "추정가격 2백만원 이하인 경우 견적서 징구 생략 가능",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항 단서"
    },
  ].freeze

  # 법령 표현 원문 대조 — 구어체 표현이 쓰였는지 검사
  EXPRESSION_CHECKS = [
    {
      wrong_patterns: [/농어촌\s*등\s*특수\s*지역/],
      correct: "지역 특성상 경쟁이 성립하지 아니하는 경우",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제30조 제1항 단서"
    },
    {
      wrong_patterns: [/2회\s*이상\s*유찰/],
      correct: "2회 이상 경쟁입찰에 부쳐도 입찰자가 없는 경우",
      source: "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제2호"
    },
  ].freeze

  def initialize
    @issues = []
  end

  def verify(text)
    @issues = []

    check_amounts(text)
    check_expressions(text)

    {
      valid: @issues.empty?,
      issue_count: @issues.size,
      issues: @issues,
      checked_at: Time.current.iso8601
    }
  end

  private

  def check_amounts(text)
    AMOUNT_CHECKS.each do |rule|
      rule[:wrong_patterns].each do |pattern|
        matches = text.scan(pattern)
        next if matches.empty?

        # 매칭된 금액이 올바른 기준과 다른지 확인
        matches.each do |match|
          captured = match.is_a?(Array) ? match.first : nil
          next if captured && amount_matches_correct?(captured, rule[:correct_amount])

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
end
