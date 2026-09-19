# frozen_string_literal: true

module ReviewLab
  # 검증실의 판정 한 건 (요구서 §3 ValidationFinding).
  #
  # severity 는 닫힌 어휘다 — 새 값을 조용히 늘리지 않는다.
  #   BLOCK : 코드가 확정한 모순. 이대로 결재·공고하면 안 된다
  #   WARN  : 누락·기준 미달 가능성. 보완이 필요하다
  #   CHECK : 코드가 결론을 못 낸다. 담당자가 원문으로 확인한다
  #   PASS  : 검사를 **실제로 돌려서** 통과했다 (값이 없어 못 잰 것은 PASS 가 아니다)
  #
  # origin 은 누가 이 판정을 냈는가다. :ai 가 낸 것은 **언제나 CHECK** 다 —
  # AI 해석이 «확정 오류»(BLOCK/WARN)로 올라가면 법령 FACT 와 섞이고,
  # «문제 없음»(PASS)으로 올라가면 검사하지 않은 것을 검사한 것처럼 보인다.
  class Finding
    SEVERITIES = %w[BLOCK WARN CHECK PASS].freeze
    ORIGINS = %i[rule ai].freeze
    AI_SEVERITY = "CHECK"

    ATTRS = %i[severity code source_document location extracted_value problem
               why_it_matters evidence suggested_action confidence origin].freeze

    attr_reader(*ATTRS)

    def initialize(severity:, code:, problem:, source_document: nil, location: nil, extracted_value: nil,
                   why_it_matters: nil, evidence: [], suggested_action: nil, confidence: "높음", origin: :rule)
      raise ArgumentError, "알 수 없는 severity: #{severity}" unless SEVERITIES.include?(severity)
      raise ArgumentError, "알 수 없는 origin: #{origin}" unless ORIGINS.include?(origin)

      @severity = origin == :ai ? AI_SEVERITY : severity
      @code = code
      @problem = problem
      @source_document = source_document
      @location = location
      @extracted_value = extracted_value
      @why_it_matters = why_it_matters
      @evidence = Array(evidence)
      @suggested_action = suggested_action
      @confidence = confidence
      @origin = origin
      freeze
    end

    def ai? = origin == :ai
    def pass? = severity == "PASS"

    def origin_label = ai? ? "AI 검토 · 추가 확인 필요" : "규칙 검사"

    def to_h = ATTRS.index_with { |a| public_send(a) }
  end
end
