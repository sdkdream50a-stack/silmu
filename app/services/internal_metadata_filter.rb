# frozen_string_literal: true

# P1-3 / §13 — INTERNAL_METADATA 와 PUBLIC_AUTHORITY_METADATA 의 경계.
#
# P0 감사에서 확인된 실제 누출 (공개 HTML `<cite>` 안):
#   "Phase A~E batch 01~03 (commits eed3ceb..12dff5d) — 법제처 OPEN API 5단계 게이트 검증"
#   "법제처 OPEN API mcp spot check + 부정확 정정 (lawId 001234·…, 2026-05-19 batch 02)"
#   "sen_2025_audit_disclosure_dashboard"
#   "GOE 2021 경기교육청 감사보고서 (조문번호 명시 없음 — 차후 정밀화 backlog)"
#
# 이 정보는 DB 에서 지우지 않는다. 관리자·감사 추적에는 필요하다.
# 다만 **공개 렌더러가 통과시키지 않는다.** 그 경계가 이 클래스다.
class InternalMetadataFilter
  # 내부 엔지니어링 흔적 패턴. 하나라도 걸리면 공개 렌더 금지.
  INTERNAL_PATTERNS = [
    /\bcommits?\b/i,                    # commit / commits
    /\b[0-9a-f]{7,40}\.\.[0-9a-f]{7,40}\b/, # 커밋 범위 eed3ceb..12dff5d
    /\bbatch\s*\d*/i,                   # batch 01
    /\blawId\b/i,
    /\bmcp\b/i,
    /\bspot\s*check\b/i,
    /\bOPEN\s*API\b/i,
    /\bdashboard\b/i,
    /\bPhase\s*[A-Z0-9]/i,              # Phase A~E, Phase 1
    /backlog/i,
    /\bseed[_\s-]?source\b/i,
    /\bparser[_\s-]?version\b/i,
    /\bbackfill\b/i,
    /\bimport[_\s-]?job\b/i,
    /\binternal\b/i,
    /[a-z0-9]+_\d{4}_[a-z0-9_]+/i,      # sen_2025_audit_disclosure_dashboard
    /차후\s*정밀화/,
    /운영\s*정합/
  ].freeze

  class << self
    # 이 문자열이 내부 메타데이터를 담고 있는가
    def internal?(text)
      return false if text.blank?

      INTERNAL_PATTERNS.any? { |re| text.to_s.match?(re) }
    end

    # 공개해도 되는 문자열만 통과시킨다. 아니면 nil.
    # 렌더러는 반드시 이 메서드를 거쳐야 한다.
    def public_only(text)
      return nil if text.blank?
      return nil if internal?(text)

      text.to_s.strip.presence
    end

    # 어떤 패턴에 걸렸는지 (진단·리포트용)
    def matched_patterns(text)
      return [] if text.blank?

      INTERNAL_PATTERNS.select { |re| text.to_s.match?(re) }.map(&:source)
    end
  end
end
