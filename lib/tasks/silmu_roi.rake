# P8 ROI 계측 — 베이스라인/주기적 GA4 스냅샷 캡처
#
# 사용:
#   bin/rake silmu:roi:snapshot LABEL=baseline_pre_p6 DAYS=7
#   bin/rake silmu:roi:snapshot LABEL=week_1_after DAYS=7
#   bin/rake silmu:roi:list
#   bin/rake silmu:roi:diff BEFORE=baseline_pre_p6 AFTER=week_1_after

namespace :silmu do
  namespace :roi do
    desc "P3/P6 영향 페이지 GA4 지표 스냅샷 저장 (LABEL= 필수, DAYS=7 기본)"
    task snapshot: :environment do
      label = ENV["LABEL"]
      abort "❌ LABEL=<식별자> 인자 필수" if label.blank?

      days  = (ENV["DAYS"] || 7).to_i
      paths = Analytics::RoiScope.all_paths
      now   = Time.current

      puts "▶ GA4 page_metrics 호출 (#{paths.size} 경로, 최근 #{days}일)"
      metrics_by_path = Ga4Service.new.page_metrics(paths: paths, days: days)

      created = 0
      paths.each do |path|
        m = metrics_by_path[path] || {}
        AnalyticsSnapshot.create!(
          label:       label,
          page_path:   path,
          days:        days,
          captured_at: now,
          metrics:     m.transform_keys(&:to_s),
          notes:       "auto via silmu:roi:snapshot"
        )
        created += 1
      end

      puts "✅ '#{label}' 스냅샷 #{created}건 저장 (captured_at=#{now.in_time_zone('Seoul').strftime('%Y-%m-%d %H:%M')})"
    end

    desc "스냅샷 라벨 목록"
    task list: :environment do
      AnalyticsSnapshot.group(:label).count.each do |label, count|
        first = AnalyticsSnapshot.for_label(label).recent.last
        last  = AnalyticsSnapshot.for_label(label).recent.first
        puts "  #{label.ljust(30)} #{count}건 · #{first&.captured_at&.strftime('%Y-%m-%d %H:%M')} → #{last&.captured_at&.strftime('%Y-%m-%d %H:%M')}"
      end
    end

    desc "두 스냅샷 라벨 비교 (BEFORE=, AFTER=)"
    task diff: :environment do
      before_label = ENV["BEFORE"]
      after_label  = ENV["AFTER"]
      abort "❌ BEFORE/AFTER 라벨 필수" if before_label.blank? || after_label.blank?

      before_map = AnalyticsSnapshot.for_label(before_label).index_by(&:page_path)
      after_map  = AnalyticsSnapshot.for_label(after_label).index_by(&:page_path)
      paths      = (before_map.keys + after_map.keys).uniq.sort

      puts format("  %-50s %12s %12s %10s", "page_path", "PV(전)", "PV(후)", "Δ%")
      paths.each do |path|
        b = before_map[path]&.pageviews || 0
        a = after_map[path]&.pageviews  || 0
        delta = b.zero? ? (a.zero? ? 0.0 : 100.0) : ((a - b) * 100.0 / b)
        puts format("  %-50s %12d %12d %+9.1f%%", path, b, a, delta)
      end
    end
  end
end
