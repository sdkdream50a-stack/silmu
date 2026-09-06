# frozen_string_literal: true

# P2 R1 — 데이터 정합 lint. 운영에서도 read-only 로 돌릴 수 있다.
#
#   bin/rake silmu:faq_integrity       # topics.faqs 저장 형태 · 도달 불가 FAQ
#   bin/rake silmu:category_integrity  # 라우트 밖 category (내비게이션 고아)
#
# 왜 필요한가: `Topic#faq_list` 는 파싱 실패를 `rescue` 로 삼키고 `[]` 를 돌려준다.
# 그 방어 덕분에 화면은 안 죽지만 **FAQ 가 사라진 사실도 같이 조용해진다.**
# 2026-09-06 감사에서 공개 토픽 2건의 FAQ 9건이 그렇게 몇 달간 안 보이고 있었다.
# 조용히 삼키는 rescue 는 반드시 "건수 0 을 강제하는 검사"와 짝이어야 한다.
namespace :silmu do
  desc "topics.faqs 저장 형태 검사 — 도달 불가 FAQ 가 1건이라도 있으면 실패"
  task faq_integrity: :environment do
    buckets = Hash.new { |h, k| h[k] = [] }
    authored  = 0
    reachable = 0

    Topic.find_each do |topic|
      raw = topic.faqs
      buckets[FaqPayloadNormalizer.classify(raw)] << topic
      authored  += FaqPayloadNormalizer.authored_count(raw)
      reachable += topic.faq_list.size
    end

    lost = authored - reachable

    puts "[FAQ INTEGRITY] Topic #{Topic.count}건"
    %i[array_ok string_parseable string_broken string_other empty].each do |kind|
      puts format("  %-18s %d", kind.to_s.upcase, buckets[kind].size)
    end
    puts "  FAQ_AUTHORED       #{authored}"
    puts "  FAQ_REACHABLE      #{reachable}"
    puts "  FAQ_LOST           #{lost}"

    (buckets[:string_broken] + buckets[:string_other]).each do |topic|
      status, detail = FaqPayloadNormalizer.call(topic.faqs)
      puts "  ✗ #{topic.slug} (published=#{topic.published}) — #{status}: #{detail.to_s.truncate(80)}"
    end
    buckets[:string_parseable].each do |topic|
      puts "  △ #{topic.slug} — jsonb 가 JSON 문자열(이중 인코딩). faq_list 가 구제 중이나 잠재 결함"
    end

    if lost.positive? || buckets[:string_broken].any? || buckets[:string_other].any?
      warn "[FAIL] 도달 불가 FAQ #{lost}건 · 복구 불가 payload #{buckets[:string_other].size}건"
      exit 1
    end

    puts "[OK] 도달 불가 FAQ 0건"
  end

  desc "topics.category 가 라우트 허용값 안에 있는지 검사 — 고아 1건이라도 있으면 실패"
  task category_integrity: :environment do
    # 허용값 정본 = config/routes.rb 의 `topics/:key` constraint.
    # 상수를 새로 만들면 정본이 둘이 된다 → 라우트에서 직접 읽고, 못 읽으면 실패시킨다(추측 금지).
    route = Rails.application.routes.routes.find { |r| r.name == "topics_category" }
    # constraints 는 비어 있다(Rails 8) — 실제 정본은 requirements[:key] 의 Regexp 다.
    pattern = route&.requirements&.dig(:key)

    if pattern.nil?
      warn "[FAIL] topics_category 라우트의 key constraint 를 읽지 못했다 — 허용값 정본 불명"
      exit 1
    end

    allowed = pattern.source.delete("^a-z|").split("|").reject(&:empty?).sort
    puts "[CATEGORY INTEGRITY] 허용값(라우트 constraint 기준) #{allowed.size}종: #{allowed.join(' ')}"

    orphans = Topic.where.not(category: allowed).or(Topic.where(category: nil))
    orphans.find_each do |topic|
      puts "  ✗ #{topic.slug} — category=#{topic.category.inspect} (published=#{topic.published})"
    end

    if orphans.exists?
      warn "[FAIL] 라우트 밖 category #{orphans.count}건 — 카테고리 내비에서 고아가 된다"
      exit 1
    end

    puts "[OK] 라우트 밖 category 0건"
  end
end
