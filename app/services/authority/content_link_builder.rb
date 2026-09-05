# frozen_string_literal: true

require "set"

# P1.5 §13·§42 — Impact Graph 의 간선을 만든다.
#
# **새 지식을 만들지 않는다.** P1 에서 이미 만든 자산을 그대로 쓴다:
#   · AuditCase#legal_basis  → LegalReferenceResolver (HIGH confidence 만)
#   · config/tool_trust.yml  → ToolTrust (도구 계산 근거)
# 해석되지 않는 참조는 링크하지 않는다 — 추측 연결은 잘못된 영향 판정을 만든다.
module Authority
  class ContentLinkBuilder
    Result = Struct.new(:created, :skipped_unresolved, :skipped_no_document, :existing, keyword_init: true)

    def initialize(dry_run: true)
      @dry_run = dry_run
      @created = 0
      @unresolved = 0
      @no_document = 0
      @existing = 0
      # dry-run 은 DB 에 쓰지 않으므로 exists? 만으로는 같은 링크를 두 번 세게 된다.
      # 계획된 키를 메모리에 기억해 실제 적용 결과와 수치가 일치하게 한다.
      @planned = Set.new
    end

    def build_all
      build_audit_cases
      build_tools
      Result.new(created: @created, skipped_unresolved: @unresolved,
                 skipped_no_document: @no_document, existing: @existing)
    end

    # 감사사례: legal_basis 문자열 → 해석 → 등록된 문서에만 연결
    def build_audit_cases
      AuditCase.where.not(legal_basis: [ nil, "" ]).find_each do |ac|
        LegalReferenceResolver.resolve(ac.legal_basis).each do |ref|
          link_reference("AuditCase", ac.id, nil, ref, "EVIDENCED_BY")
        end
      end
    end

    # 도구: tool_trust.yml 의 laws 문자열 → 해석 → 연결
    def build_tools
      ToolTrust.registered_tool_keys.each do |key|
        ToolTrust.for(key).legal_references.each do |ref|
          link_reference("Tool", nil, key, ref, "CALCULATES_WITH")
        end
      end
    end

    private

    # 해석기가 HIGH 로 확정한 참조만 간선이 된다.
    def link_reference(content_type, content_id, content_key, ref, relationship)
      unless ref.confidence == "HIGH" && ref.canonical_name.present?
        @unresolved += 1
        return
      end

      document = AuthorityDocument.find_by(title: ref.canonical_name)
      if document.nil?
        @no_document += 1   # 아직 감시 등록되지 않은 법령 — 링크하지 않는다
        return
      end

      article, clause = split_reference(ref)
      attrs = {
        content_type: content_type, content_id: content_id, content_key: content_key,
        authority_document_id: document.id, article_reference: article
      }

      if ContentAuthorityLink.exists?(attrs) || @planned.include?(attrs)
        @existing += 1
        return
      end

      @planned << attrs
      @created += 1
      return if @dry_run

      ContentAuthorityLink.create!(
        **attrs,
        clause_reference: clause,
        relationship_type: relationship,
        confidence: "HIGH",
        derivation_source: "LegalReferenceResolver(#{ref.resolution_source})"
      )
    end

    # "제25조 제1항 제5호" → ["제25조", "제1항 제5호"]
    def split_reference(ref)
      arts = Array(ref.articles)
      main = arts.find { |a| a.match?(/\A제\d+조/) }
      rest = arts.reject { |a| a == main }
      [ main, rest.join(" ").presence ]
    end
  end
end
