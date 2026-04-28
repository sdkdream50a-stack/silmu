# frozen_string_literal: true

# Guide.topic_slug 자동 매핑 백필.
# 운영 DB 진단 결과 Guide 103건 중 91건(88.3%)이 topic_slug 미연결 상태.
# 3단계 fallback으로 자동 매핑하고 미매칭 건은 stdout으로 보고.
namespace :backfill do
  # Guide.series (한글) → 시리즈 메인 토픽 slug 매핑.
  # silmu의 Guide는 대부분 "<주제> — 왕초보 완전정복 N편" 형식이라
  # 시리즈 단위로 메인 토픽에 묶어 연결한다 (1:N).
  SERIES_TO_TOPIC = {
    "수의계약_완전정복"   => "private-contract",
    "입찰_완전정복"       => "bidding",
    "출장여비_완전정복"   => "travel-expense"
    # 예산편성/예산집행/인사복무/공사계약/지방보조금 시리즈는
    # 메인 토픽이 아직 없거나 분산되어 있어 미매칭으로 보고
  }.freeze

  # title boilerplate 제거 패턴 — "이란 무엇인가", "완전정복 N편", "왕초보" 등
  TITLE_NOISE = [
    /\s*[—–-]\s*왕초보\s*완전정복\s*\d+편.*$/,
    /\s*[—–-]\s*완전정복\s*\d+편.*$/,
    /\s*완전정복\s*\d+편\s*[—–-]?.*$/,
    /\s*[—–-]\s*실무\s*\d+문답.*$/,
    /이란\s*무엇인가.*$/,
    /\s*기초$/,
    /\s+완전\s*정리.*$/,
    /\s+완전\s*가이드.*$/
  ].freeze

  NORMALIZE_TITLE = ->(title) {
    t = title.to_s.dup
    TITLE_NOISE.each { |re| t = t.gsub(re, "") }
    t.strip
  }

  desc "Guide.external_link/series/title/keywords 기반 topic_slug 자동 매핑"
  task guide_topic_slug: :environment do
    targets = Guide.where(topic_slug: [ nil, "" ])
    puts "🔗 Guide-Topic 백필 시작 (대상 #{targets.count}건 / 전체 #{Guide.count}건)"
    puts ""

    matched = 0
    unmatched = []
    valid_topic_slugs = Topic.pluck(:slug).to_set

    targets.find_each do |g|
      slug = nil
      reason = nil

      # 1단계: external_link "/topics/<slug>" 패턴
      if g.external_link.present? && g.external_link =~ %r{^/topics/([^/?#]+)}
        candidate = ::Regexp.last_match(1)
        if valid_topic_slugs.include?(candidate)
          slug = candidate
          reason = "external_link"
        end
      end

      # 2단계: series → 메인 토픽 매핑
      if slug.nil? && g.series.present?
        candidate = SERIES_TO_TOPIC[g.series]
        if candidate && valid_topic_slugs.include?(candidate)
          slug = candidate
          reason = "series:#{g.series}"
        end
      end

      # 3단계: boilerplate 제거 후 Topic.name 정확 일치
      cleaned = NORMALIZE_TITLE.call(g.title)
      if slug.nil? && cleaned.present?
        t = Topic.find_by(name: cleaned)
        if t
          slug = t.slug
          reason = "title_normalized"
        end
      end

      # 4단계: cleaned title을 keywords/name ILIKE — 1건만 매칭 시
      if slug.nil? && cleaned.present?
        like_q = "%#{Topic.sanitize_sql_like(cleaned)}%"
        candidates = Topic.published.where("keywords ILIKE ? OR name ILIKE ?", like_q, like_q).to_a
        if candidates.size == 1
          slug = candidates.first.slug
          reason = "keyword_unique"
        end
      end

      if slug
        g.update_column(:topic_slug, slug)
        matched += 1
        puts "✅ [#{g.id}] #{g.title.to_s.truncate(50)} → #{slug} (#{reason})"
      else
        unmatched << g
        puts "❓ [#{g.id}] #{g.title.to_s.truncate(50)} — 미매칭"
      end
    end

    puts ""
    puts "—" * 60
    puts "📊 백필 결과"
    puts "   매칭 성공: #{matched}건"
    puts "   미매칭:    #{unmatched.size}건"
    puts "   전체 미연결 잔여: #{Guide.where(topic_slug: [ nil, '' ]).count}건"
    puts ""

    if unmatched.any?
      puts "💡 미매칭 Guide 목록 (수동 매핑 필요):"
      unmatched.each do |g|
        ext = g.external_link.present? ? " external_link=#{g.external_link}" : ""
        puts "   • [#{g.id}] #{g.title.to_s.truncate(70)}#{ext}"
      end
    end
  end
end
