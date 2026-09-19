# frozen_string_literal: true

module ReviewLab
  # 검토 1회의 결과 묶음 (요구서 §3 DocumentReview). DB 에 저장하지 않는다 — 응답으로 렌더하고 사라진다.
  #
  # coverage 는 «무엇을 검사했고 무엇을 못 했는가» 다.
  # 검사할 값이 하나도 없었는데 finding 이 0 이면 화면은 «문제 없음» 으로 읽힌다.
  # 그 둘을 구별하려고 실행한 규칙 수와 못 돌린 규칙(이유 포함)을 같이 싣는다.
  class DocumentReview
    KINDS = { quote: "견적서 검토", package: "입찰공고 패키지 검토" }.freeze

    attr_reader :kind, :documents, :fields, :findings, :comparisons, :skipped_rules, :extras
    attr_accessor :rules_run

    def initialize(kind:, documents:)
      @kind = kind
      @documents = documents
      @fields = {}          # document_label => { key => [ExtractedField] }
      @findings = []
      @comparisons = []     # [{ key:, name:, cells: { label => ExtractedField|nil }, verdict: }]
      @skipped_rules = []   # [{ code:, reason: }]
      @rules_run = 0
      @extras = {}
    end

    def kind_label = KINDS.fetch(kind)

    def add(finding) = (@findings << finding) && finding

    def skip(code, reason) = @skipped_rules << { code: code, reason: reason }

    def readable_documents = documents.select(&:ok?)
    def unreadable_documents = documents.reject(&:ok?)

    # 읽을 수 있는 문서가 없거나, 규칙을 하나도 못 돌렸으면 «검사 불가» 다. PASS 로 보이면 안 된다.
    def inconclusive? = readable_documents.empty? || rules_run.zero?

    def counts
      Finding::SEVERITIES.index_with { |s| findings.count { |f| f.severity == s } }
    end

    def rule_findings = findings.reject(&:ai?)
    def ai_findings = findings.select(&:ai?)

    SEVERITY_ORDER = Finding::SEVERITIES.each_with_index.to_h.freeze

    def sorted_findings(list = findings)
      list.sort_by { |f| [ SEVERITY_ORDER.fetch(f.severity), f.code ] }
    end

    def headline
      return "검사할 수 있는 값을 찾지 못했습니다 — 결과를 «문제 없음» 으로 보면 안 됩니다" if inconclusive?

      c = counts
      if c["BLOCK"].positive?
        "확정 오류 #{c['BLOCK']}건 — 고친 뒤 사용하세요"
      elsif c["WARN"].positive?
        "보완 필요 #{c['WARN']}건 · 확인 필요 #{c['CHECK']}건"
      elsif c["CHECK"].positive?
        "확정 오류는 없고, 담당자 확인이 필요한 항목이 #{c['CHECK']}건 있습니다"
      else
        "실행한 규칙 #{rules_run}개에서 문제를 찾지 못했습니다(검사하지 못한 항목은 아래 참고)"
      end
    end
  end
end
