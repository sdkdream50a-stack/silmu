# frozen_string_literal: true

module ReviewLab
  # 개인정보 의심 패턴 탐지·가림. 결정적 정규식만 쓴다.
  #
  # 두 가지 용도
  #   1. 검토 결과에 «이 문서에 주민등록번호 형태가 N곳 있다» 를 **위치만** 알린다 — 값은 다시 보여주지 않는다.
  #   2. 사용자가 외부 AI 를 선택했을 때 보내기 전에 가린다.
  #
  # 사업자등록번호는 개인정보 패턴에 넣지 않는다(견적서 검증에 필요한 업체 식별값). 대신 AI 로 보낼 때는 가린다.
  class PiiScanner
    PATTERNS = {
      rrn:     [ "주민등록번호 형태", /\b\d{6}\s?-\s?[1-4]\d{6}\b/ ],
      mobile:  [ "휴대전화번호 형태", /\b01[016789]\s?-?\s?\d{3,4}\s?-?\s?\d{4}\b/ ],
      email:   [ "이메일 주소", /\b[\w.+-]+@[\w-]+\.[\w.-]+\b/ ],
      account: [ "계좌번호 형태", /(?:계좌|입금|예금주)[^\n]{0,20}?\b\d{2,6}-\d{2,6}-\d{2,8}(?:-\d{1,4})?\b/ ]
    }.freeze
    AI_ONLY_PATTERNS = {
      business_no: /\b\d{3}-\d{2}-\d{5}\b/,
      phone:       /\b0\d{1,2}-\d{3,4}-\d{4}\b/
    }.freeze
    MASK = "[가림]"

    # => [{ kind:, label:, locator: }] (값은 담지 않는다)
    def self.scan(document)
      document.segments.flat_map do |seg|
        PATTERNS.filter_map do |kind, (label, re)|
          { kind: kind, label: label, locator: seg[:locator] } if seg[:text].match?(re)
        end
      end
    end

    def self.mask(text)
      out = text.to_s.dup
      PATTERNS.each_value { |(_label, re)| out.gsub!(re, MASK) }
      AI_ONLY_PATTERNS.each_value { |re| out.gsub!(re, MASK) }
      out
    end
  end
end
