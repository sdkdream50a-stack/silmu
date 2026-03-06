# Backfill: sector 배정 및 Guide.topic_slug 자동 추출
# 실행: rails runner db/seeds/backfill_sectors.rb

puts "=== [1/3] Guide.topic_slug 자동 추출 ==="
updated = 0
Guide.where("external_link LIKE '/topics/%'").find_each do |g|
  slug = g.external_link.delete_prefix("/topics/")
  g.update_column(:topic_slug, slug)
  updated += 1
  puts "  Guide[#{g.id}] #{g.title} → topic_slug: #{slug}"
end
puts "  완료: #{updated}건 업데이트"

puts "\n=== [2/3] Topic sector 배정 (property, subsidy → local_gov) ==="
local_gov_count = Topic.where(category: %w[property subsidy]).update_all(sector: 1)
puts "  local_gov 배정: #{local_gov_count}건"
puts "  (나머지는 common 기본값 유지)"

puts "\n=== [3/3] 결과 확인 ==="
puts "\n[Topics] sector별 카테고리 분포:"
Topic.published.group(:sector, :category).count.each do |(sector, cat), cnt|
  sector_label = { 0 => "common", 1 => "local_gov", 2 => "edu" }[sector]
  puts "  #{sector_label}/#{cat}: #{cnt}건"
end

puts "\n[Guides] topic_slug 연결 현황:"
puts "  topic_slug 있음: #{Guide.where.not(topic_slug: nil).count}건"
puts "  topic_slug 없음: #{Guide.where(topic_slug: nil).count}건"

puts "\n[AuditCases] sector 분포:"
AuditCase.published.group(:sector).count.each do |sector, cnt|
  sector_label = { 0 => "common", 1 => "local_gov", 2 => "edu" }[sector]
  puts "  #{sector_label}: #{cnt}건"
end

puts "\n=== Backfill 완료 ==="
