# P8 ROI 계측 — 추적 대상 페이지 경로 정의
#
# P3 Sprint 2 (표준어 후처리 UI 배지) + P6 Phase 2 (ContentMigration 정정 토픽/감사사례)
# 영향 면 페이지 경로를 한 곳에서 관리.

module Analytics
  module RoiScope
    P3_PATHS = [
      "/tools/ai-assistant",
      "/tools/official-document"
    ].freeze

    P6_TOPIC_SLUGS = %w[
      bid-announcement
      restricted-bidding
      bid-deposit
    ].freeze

    P6_AUDIT_CASE_SLUGS = %w[
      reserve-fund-violation
      budget-transfer-limit-violation
      budget-transfer-without-council-approval
      budget-execution-before-approval
      accounting-officer-dual-role-fraud
      business-expense-personal-use
      accounting-data-falsification
      budget-appropriation-mistake
      expenditure-over-budget
      travel-expense-double-claim
      budget-misuse
      contingency-fund-misuse
      budget-lapse-improper-carryover
      contingency-fund-purpose-misuse
      guideline-excess-budget-compilation
      accommodation-allowance-false-claim
      domestic-travel-transport-overclaim
    ].freeze

    def self.topic_paths
      P6_TOPIC_SLUGS.map { |s| "/topics/#{s}" }
    end

    def self.audit_case_paths
      P6_AUDIT_CASE_SLUGS.map { |s| "/audit-cases/#{s}" }
    end

    def self.all_paths
      (P3_PATHS + topic_paths + audit_case_paths).freeze
    end

    # 단일 슬러그가 ContentMigration 영향권인지 — gtag 이벤트 발화용
    def self.affected_topic?(slug)
      P6_TOPIC_SLUGS.include?(slug)
    end

    def self.affected_audit_case?(slug)
      P6_AUDIT_CASE_SLUGS.include?(slug)
    end
  end
end
