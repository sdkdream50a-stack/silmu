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
    # `\b` 는 쓰지 않는다 — Ruby 는 한글을 단어 문자로 봐서 «주민번호900101-1234567» 처럼 라벨에 붙은 번호를
    # 놓친다(보안 리뷰 실측). 숫자 경계는 (?<!\d) / (?!\d) 로만 판정하고, 검사 전에 NFKC 로 전각 숫자를 푼다.
    PATTERNS = {
      rrn:     [ "주민·외국인등록번호 형태", /(?<!\d)\d{6}[\s\-]?[1-8]\d{6}(?!\d)/ ],
      mobile:  [ "휴대전화번호 형태", /(?<!\d)01[016789][\s.\-]?\d{3,4}[\s.\-]?\d{4}(?!\d)/ ],
      email:   [ "이메일 주소", /[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+/ ],
      account: [ "계좌번호 형태", /(?:계좌|입금|예금주|은행|농협|신협|새마을금고|우체국)[^\n]{0,20}?(?<!\d)\d{2,6}-\d{2,6}-\d{2,8}(?:-\d{1,4})?(?!\d)/ ]
    }.freeze
    AI_ONLY_PATTERNS = {
      business_no: /(?<!\d)\d{3}-\d{2}-\d{5}(?!\d)/,
      phone:       /(?<!\d)0\d{1,2}[\s.\-]\d{3,4}[\s.\-]\d{4}(?!\d)/,
      long_digits: /(?<!\d)\d{2,6}-\d{2,6}-\d{4,8}(?!\d)/   # 키워드 없는 계좌번호 형태
    }.freeze
    MASK = "[가림]"

    # => [{ kind:, label:, locator: }] (값은 담지 않는다)
    def self.scan(document)
      document.segments.flat_map do |seg|
        PATTERNS.filter_map do |kind, (label, re)|
          { kind: kind, label: label, locator: seg[:locator] } if normalize(seg[:text]).match?(re)
        end
      end
    end

    def self.normalize(text) = text.to_s.unicode_normalize(:nfkc)

    def self.mask(text)
      out = normalize(text)
      PATTERNS.each_value { |(_label, re)| out.gsub!(re, MASK) }
      AI_ONLY_PATTERNS.each_value { |re| out.gsub!(re, MASK) }
      out
    end
  end
end
