# 2026-05-19 권위자 P7+P4 권고 #C — Phase A~E batch #1~#4 정정 콘텐츠에 verification 정보 backfill
# 사용: bin/rake silmu:backfill_verification
namespace :silmu do
  desc "Phase A~E batch #1~#4 정정 콘텐츠에 last_verified_at + verification_method/source 설정"
  task backfill_verification: :environment do
    source = "Phase A~E batch #1~#4 (commits eed4ceb..35dff5d) — 법제처 OPEN API 5단계 게이트 검증"
    at = Time.zone.parse("2026-05-19 12:00")
    method = "mcp_law_api"

    # batch #1~#4에서 정정한 Topic (직접 시드/콘텐츠 변경)
    topic_slugs = %w[
      budget-compilation-guideline
      budget-item-standard
      budget-lapse
      bid-deposit
      bid-announcement
      restricted-bidding
      expenditure-commitment
      budget-execution
    ]

    # batch #1~#4에서 dispatcher 실행으로 sections 갱신된 Guide 시리즈 (전 50편)
    guide_slugs =
      (1..10).map { |n| "budget-planning-complete-#{n}" } +
      (1..10).map { |n| "budget-execution-complete-#{n}" } +
      (1..10).map { |n| "construction-contract-complete-#{n}" } +
      (1..10).map { |n| "hr-welfare-complete-#{n}" } +
      (1..10).map { |n| "travel-expense-complete-#{n}" }

    # batch #1~#4 + 권위자 재검증에서 patch 시드로 정정한 AuditCase
    audit_case_slugs = %w[
      contingency-fund-misuse
      budget-lapse-improper-carryover
      contingency-fund-purpose-misuse
      guideline-excess-budget-compilation
      accommodation-allowance-false-claim
      domestic-travel-transport-overclaim
    ]

    topic_count = Topic.where(slug: topic_slugs).count
    guide_count = Guide.where(slug: guide_slugs).count
    audit_count = AuditCase.where(slug: audit_case_slugs).count

    puts "▣ backfill 대상:"
    puts "  Topic: #{topic_count} / #{topic_slugs.size}"
    puts "  Guide: #{guide_count} / #{guide_slugs.size}"
    puts "  AuditCase: #{audit_count} / #{audit_case_slugs.size}"
    puts ""

    Topic.where(slug: topic_slugs).update_all(
      last_verified_at: at,
      verification_method: method,
      verification_source: source
    )
    Guide.where(slug: guide_slugs).update_all(
      last_verified_at: at,
      verification_method: method,
      verification_source: source
    )
    AuditCase.where(slug: audit_case_slugs).update_all(
      last_verified_at: at,
      verification_method: method,
      verification_source: source
    )

    puts "✅ Topic #{topic_count} + Guide #{guide_count} + AuditCase #{audit_count} backfill 완료"
    puts ""
    puts "▣ 통계 (전체 콘텐츠 대비 검증 비율):"
    puts "  Topic verified: #{Topic.verified_recently.count} / #{Topic.count}"
    puts "  Guide verified: #{Guide.verified_recently.count} / #{Guide.count}"
    puts "  AuditCase verified: #{AuditCase.verified_recently.count} / #{AuditCase.count}"
  end
end
