# 공공데이터 공통표준용어 후처리 서비스
# 행정안전부 「공공데이터 공통표준용어」(13,176건)를 기반으로
# 사용자 입력/AI 출력 텍스트의 비표준어를 표준어로 교정 + 변경 로그 반환
#
# 사용 예:
#   result = StandardTermCorrector.call("계약 상대자에게 대가 지급")
#   # => {
#   #   original: "계약 상대자에게 대가 지급",
#   #   corrected: "계약상대자에게 대가지급",
#   #   changes: [
#   #     { from: "계약 상대자", to: "계약상대자", position: 0 },
#   #     { from: "대가 지급", to: "대가지급", position: 9 }
#   #   ],
#   #   compliance_rate: 1.0
#   # }
class StandardTermCorrector
  # 한글은 조사(은/는/이/가/…)가 띄어쓰기 없이 명사 뒤에 바로 붙는다 — 그래서 "뒤에 한글이
  # 오면 무조건 경계 아님"으로 막으면 "계약자와"·"계약자는" 같은 정상 문장까지 막힌다.
  # 반대로 뒤에 오는 한글이 조사가 아니면(예: "계약자료"의 "료") 다른 낱말 안에 우연히
  # 포함된 것이므로 막아야 한다. 열린 목록(임의 한글 차단)이 아니라 닫힌 조사 목록으로
  # "허용"을 판단한다(자유 치환의 회귀를 막기 위한 닫힌 어휘 원칙).
  PARTICLES = %w[
    은 는 이 가 을 를 의 에게서 에서 에게 에 께서 께 로서 로써 으로 로 와 과
    부터 까지 보다 처럼 같이 마저 조차 뿐 밖에 이나마 이나 나 이며 며
    이라도 라도 이라는 라는 이다 다 이고 고 이지만 지만 이라고 라고 하고 랑 이랑 도 만
  ].sort_by { |p| -p.length }.freeze
  PARTICLE_PATTERN = PARTICLES.map { |p| Regexp.escape(p) }.join("|")

  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text.to_s
    @changes = []
  end

  def call
    return empty_result if @text.blank?

    corrected = @text.dup
    # 긴 이음동의어 먼저 처리 (greedy match 충돌 방지)
    sorted = StandardTerm.synonym_index.sort_by { |syn, _| -syn.length }
    sorted.each do |synonym, standard|
      next if synonym.blank? || standard.blank?
      next if synonym == standard
      # F4-2: 2글자 이하 짧은 이음동의어는 일반어 과잉치환(false positive) 위험으로 제외
      next if synonym.length <= 2
      # 표준어 자체에 이음동의어가 substring으로 포함되면 skip
      # (예: "종합심사" ⊂ "종합심사낙찰제" → 치환 후 재매칭 방지)
      next if standard.include?(synonym)

      # 단어 경계 없는 부분 문자열 치환은 다른 단어 안에 우연히 포함된 문자열까지 바꿔버린다
      # (예: "계약자료"의 "계약자", "CHRISTMAS"의 "MAS"). 앞은 한글·영문·숫자가 이어지지 않아야
      # 하고, 뒤는 끝나거나(공백·문장부호) 조사가 붙는 경우만 진짜 단어 경계로 본다.
      pattern = /(?<![\p{Hangul}A-Za-z0-9])#{Regexp.escape(synonym)}(?=$|[^\p{Hangul}A-Za-z0-9]|(?:#{PARTICLE_PATTERN})(?:$|[^\p{Hangul}A-Za-z0-9]))/
      offset = 0
      while (m = corrected.match(pattern, offset))
        idx = m.begin(0)
        @changes << { from: synonym, to: standard, position: idx }
        corrected = corrected[0...idx] + standard + corrected[(idx + synonym.length)..]
        offset = idx + standard.length
      end
    end

    {
      original: @text,
      corrected: corrected,
      changes: @changes,
      compliance_rate: compliance_rate
    }
  end

  private

  # 비표준어 매칭 횟수 기반 준수율 (0.0~1.0)
  # 변경 0건이면 1.0 (이미 표준어), 변경 많을수록 낮음
  # 어절 수 대비 비표준어 비율로 계산
  def compliance_rate
    word_count = @text.scan(/\S+/).size
    return 1.0 if word_count.zero?

    deficient = @changes.size
    rate = 1.0 - (deficient.to_f / word_count)
    rate.clamp(0.0, 1.0).round(3)
  end

  def empty_result
    { original: @text, corrected: @text, changes: [], compliance_rate: 1.0 }
  end
end
