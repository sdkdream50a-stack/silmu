# frozen_string_literal: true
# S4 — published 콘텐츠 E-E-A-T 필수 슬롯 게이트 (색인 회복 재발방지)
#
# plan v2 S4 대책: published 게이트는 N자 임계가 아니라 "필수 슬롯 충족" —
# 출처(verification_source)·검증일(last_verified_at)·검토상태(needs_review=false) +
# 타입별 슬롯(guide author/external_link, audit_case source)을 점검한다.
# 어느 published 페이지가 E-E-A-T 보강이 필요한지 자동 식별 → 색인 회복 작업 큐.
#
# DB 의존: 빈 환경에서는 [SKIP] exit 0 (legal_lint 빠른 워크플로와 분리).
# 기본 정보성(exit 0). STRICT=1이면 위반 시 exit 1 (CI 게이트로 사용).
# 사용: bin/rake silmu:content_quality            # 정보성 리포트
#       STRICT=1 bin/rake silmu:content_quality   # 게이트(위반 시 실패)
namespace :silmu do
  desc "S4 — published 콘텐츠 E-E-A-T 필수 슬롯 점검 (출처·검증일·검토상태)"
  task content_quality: :environment do
    unless defined?(Topic) && Topic.table_exists?
      puts "[SKIP] topics 테이블 없음 (마이그레이션 미실행)"
      exit 0
    end

    total = Topic.published.count + Guide.published.count + AuditCase.published.count
    if total.zero?
      puts "[SKIP] published 콘텐츠 0건 (빈 DB) — bin/rails db:seed 후 실행"
      exit 0
    end

    violations = []
    record = lambda do |kind, id, slots|
      missing = slots.reject { |_name, present| present }.keys
      violations << { kind: kind, id: id, missing: missing } if missing.any?
    end

    Topic.published.find_each do |t|
      record.call("Topic", t.slug, {
        "출처" => t.verification_source.present?,
        "검증일" => t.last_verified_at.present?,
        "검토완료(needs_review=false)" => !t.needs_review,
        "고유 해설" => (t.summary.to_s + t.commentary.to_s).strip.length >= 50
      })
    end

    Guide.published.find_each do |g|
      record.call("Guide", g.slug, {
        "출처" => g.verification_source.present?,
        "검증일" => g.last_verified_at.present?,
        "저자/외부링크" => (g.author.present? || g.external_link.present?)
      })
    end

    AuditCase.published.find_each do |a|
      record.call("AuditCase", a.slug, {
        "출처" => (a.verification_source.present? || a.source.present?),
        "검증일" => a.last_verified_at.present?
      })
    end

    if violations.empty?
      puts "[OK] published 콘텐츠 E-E-A-T 슬롯 충족 (#{total}건 점검)"
      exit 0
    end

    strict = ENV["STRICT"].present?
    puts "[#{strict ? 'FAIL' : 'WARN'}] E-E-A-T 슬롯 미충족 #{violations.size}/#{total}건"
    violations.group_by { |v| v[:kind] }.each do |kind, items|
      puts "\n## #{kind} (#{items.size}건)"
      items.first(20).each { |v| puts "  - #{v[:id]}: 누락 [#{v[:missing].join(', ')}]" }
    end
    puts "\n→ 누락 슬롯을 채워 색인 품질(E-E-A-T) 회복. STRICT=1로 CI 게이트화 가능."
    exit(strict ? 1 : 0)
  end
end
