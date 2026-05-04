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
      # 표준어 자체에 이음동의어가 substring으로 포함되면 skip
      # (예: "종합심사" ⊂ "종합심사낙찰제" → 치환 후 재매칭 방지)
      next if standard.include?(synonym)

      idx = corrected.index(synonym)
      while idx
        @changes << { from: synonym, to: standard, position: idx }
        corrected = corrected.sub(synonym, standard)
        idx = corrected.index(synonym, idx + standard.length)
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
