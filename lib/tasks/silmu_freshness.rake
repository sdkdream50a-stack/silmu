# frozen_string_literal: true

# P1.5 — Freshness Engine 운용 태스크
#
# 안전 규칙: 이 네임스페이스의 어떤 태스크도 게시 콘텐츠 본문을 수정하지 않는다(§4).
#            쓰는 대상은 authority_* 테이블과 콘텐츠의 freshness_state 3컬럼뿐이다.
namespace :silmu do
  namespace :freshness do
    desc "감시 대상 등록 (Canary source registry 시드, 멱등)"
    task seed_sources: :environment do
      load Rails.root.join("db/seeds/authority_sources.rb")
    end

    desc "현행성 점검 실행 (변경 감지 → 영향 분석 → 검토 태스크). DRY_RUN=1 이면 태스크 생성 안 함"
    task check: :environment do
      dry = ENV["DRY_RUN"].present?
      limit = (ENV["LIMIT"] || AuthorityFreshnessCheckJob::MAX_DOCUMENTS_PER_RUN).to_i
      report = AuthorityFreshnessCheckJob.new.perform(limit: limit, dry_run: dry)
      puts "freshness check#{' (DRY-RUN)' if dry}: #{report.to_json}"
    end

    desc "콘텐츠 ↔ 근거 링크 생성 (기본 dry-run, APPLY=1 이면 실제 생성)"
    task build_links: :environment do
      apply = ENV["APPLY"].present?
      r = Authority::ContentLinkBuilder.new(dry_run: !apply).build_all
      puts "link build#{apply ? '' : ' (DRY-RUN)'}: 생성#{apply ? '' : ' 예정'}=#{r.created} " \
           "· 미해석(링크 안 함)=#{r.skipped_unresolved} · 미등록법령(링크 안 함)=#{r.skipped_no_document} " \
           "· 기존=#{r.existing}"
      puts "현재 총 링크=#{ContentAuthorityLink.count}"
    end

    desc "관측 대시보드 (§26)"
    task status: :environment do
      puts "=" * 72
      puts "SILMU FRESHNESS STATUS  #{Time.current.strftime('%Y-%m-%d %H:%M')}"
      puts "=" * 72

      puts "\n[감시 소스]"
      AuthoritySource.order(:key).each do |s|
        puts "  #{s.key.ljust(20)} tier#{s.authority_tier} #{s.source_type.ljust(16)} " \
             "enabled=#{s.enabled} 주기=#{s.check_interval_hours}h"
        puts "    마지막 검사=#{s.last_checked_at&.strftime('%Y-%m-%d %H:%M') || '없음'} " \
             "마지막 성공=#{s.last_success_at&.strftime('%Y-%m-%d %H:%M') || '없음'} " \
             "연속실패=#{s.failure_count}#{" (#{s.last_failure_kind})" if s.last_failure_kind}"
      end

      puts "\n[문서 · 현행 버전]"
      AuthorityDocument.includes(:current_version).order(:key).each do |d|
        v = d.current_version
        puts "  #{(d.short_title || d.title).to_s.ljust(26)} " \
             "#{v ? v.effective_label.ljust(20) : '미수집'.ljust(20)} " \
             "버전수=#{d.authority_versions.count} 링크=#{ContentAuthorityLink.where(authority_document_id: d.id).count}"
      end

      puts "\n[변경 이벤트]"
      puts "  전체=#{AuthorityChangeEvent.count} · 미분석=#{AuthorityChangeEvent.unanalyzed.count} · 열림=#{AuthorityChangeEvent.open.count}"
      AuthorityChangeEvent.group(:change_type).count.each { |k, v| puts "    #{k}: #{v}" }

      puts "\n[검토 큐]"
      puts "  열림=#{AuthorityReviewTask.open.count} / 전체=#{AuthorityReviewTask.count}"
      AuthorityReviewTask.group(:impact_class).count.each { |k, v| puts "    impact #{k}: #{v}" }
      AuthorityReviewTask.group(:status).count.each { |k, v| puts "    status #{k}: #{v}" }

      puts "\n[콘텐츠 freshness]"
      [ Topic, Guide, AuditCase ].each do |klass|
        dist = klass.where.not(freshness_state: nil).group(:freshness_state).count
        puts "  #{klass.name.ljust(10)} 관측됨=#{dist.values.sum} / 전체=#{klass.count}  #{dist}"
      end

      puts "\n[검증 이벤트]"
      puts "  전체=#{AuthorityVerificationEvent.count} · 최근 7일=#{AuthorityVerificationEvent.where(reviewed_at: 7.days.ago..).count}"
      puts "=" * 72
    end

    desc "열린 검토 큐 출력 (§27)"
    task review_queue: :environment do
      tasks = AuthorityReviewTask.open.by_priority.includes(authority_change_event: :authority_document)
      puts "열린 검토 태스크 #{tasks.count}건"
      tasks.limit((ENV["LIMIT"] || 30).to_i).each do |t|
        e = t.authority_change_event
        puts "  [P#{t.priority}] #{t.impact_class.ljust(9)} #{t.affected_label}"
        puts "        근거=#{e.authority_document.short_title || e.authority_document.title} " \
             "변경=#{e.change_type} 시행일=#{e.effective_at || '미상'}"
        puts "        사유=#{t.impact_reason}"
      end
    end

    desc "안전 회귀: 엔진 실행이 게시 콘텐츠 본문을 바꾸지 않는지 확인 (§48)"
    task no_auto_publish_check: :environment do
      snapshot = lambda do
        {
          "Topic" => Topic.order(:id).pluck(:id, :law_content, :decree_content, :rule_content, :commentary, :summary).hash,
          "Guide" => Guide.order(:id).pluck(:id, :summary, :sections).hash,
          "AuditCase" => AuditCase.order(:id).pluck(:id, :issue, :detail, :lesson, :action_taken, :legal_basis).hash
        }
      end
      before = snapshot.call
      report = AuthorityFreshnessCheckJob.new.perform(limit: (ENV["LIMIT"] || 5).to_i)
      after = snapshot.call

      changed = before.keys.reject { |k| before[k] == after[k] }
      puts "freshness check: #{report.to_json}"
      if changed.empty?
        puts "NO_AUTO_PUBLISH: OK — 본문 무변경 (Topic/Guide/AuditCase)"
      else
        abort("NO_AUTO_PUBLISH 위반: #{changed.join(', ')} 본문이 변경되었다")
      end
    end
  end
end
