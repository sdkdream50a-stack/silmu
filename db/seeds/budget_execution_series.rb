# 예산집행 완전정복 10편 시리즈
# rails runner db/seeds/budget_execution_series.rb

require_relative "budget_execution_part1"
require_relative "budget_execution_part2"

series_name = "예산집행_완전정복"
episodes = BUDGET_EXECUTION_EPISODES_PART1 + BUDGET_EXECUTION_EPISODES_PART2

episodes.each do |ep|
  g = Guide.find_or_initialize_by(slug: ep[:slug])
  g.assign_attributes(
    title:        ep[:title],
    description:  ep[:description],
    category:     ep[:category],
    series:       series_name,
    series_order: ep[:series_order],
    sections:     ep[:sections],
    rich_media:   ep[:rich_media],
    published:    true
  )
  g.save!
  puts "✓ #{ep[:series_order]}편 저장: #{ep[:title]}"
end

puts "\n=== 예산집행 완전정복 #{episodes.size}편 시리즈 생성 완료 ==="
puts "시리즈 식별자: #{series_name}"
