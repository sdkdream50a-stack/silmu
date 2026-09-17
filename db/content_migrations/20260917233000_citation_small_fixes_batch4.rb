# 조문 인용 소규모 정정 4차 (2026-09-17 전수감사 G-37)
#
# 원문(law.go.kr): 지방계약법 시행규칙 제75조(지연배상금률: 공사 0.5/1000 · 물품 제조·구매 0.8/1000 · 물품 수리·가공·대여, 용역 등 1.3/1000 ·
#   운송·보관·양곡가공 2.5/1000 — «임대차 1/1000» 없음) · 지방계약법 시행령 제90조 제3항(한도 100분의 30) ·
#   지방자치법 제54조 제3항(요구 시 15일 이내 임시회 소집 — 제56조 아님) · 지방재정법 제38조 제2항(예산편성기준 = 행정안전부령;
#   지방재정법 시행령 제37조는 없음, «5월 31일 통보» 조문 확인 안 됨).

subs = [
  [ "late-penalty", :faqs,
    "공사 0.5/1,000, 물품 제조·구매 0.8/1,000, 용역(수리·가공 등) 1.3/1,000, 운송·보관 등 2.5/1,000, 임대차 1/1,000 (1일당).",
    "공사 0.5/1,000, 물품 제조·구매 0.8/1,000, 물품 수리·가공·대여와 용역 등 1.3/1,000, 운송·보관·양곡가공 2.5/1,000 (1일당)." ],
  [ "supplementary-budget", :decree_content,
    "| 임시회 소집 | 의장은 소집 요구일로부터 15일 이내 소집 (지방자치법 제56조) |",
    "| 임시회 소집 | 지방자치단체의 장 등이 요구하면 의장은 15일 이내 소집 (지방자치법 제54조 제3항) |" ],
  [ "budget-compilation", :quick_stats, "지방재정법 시행령 제37조", "지방재정법 제38조 제2항" ],
  [ "budget-compilation", :quick_stats, "매년 5월 31일까지 통보", "행정안전부령으로 정함(통보 시기는 해당 연도 기준 확인)" ]
]

deep_sub = lambda do |value, from, to|
  case value
  when String then value.gsub(from, to)
  when Array  then value.map { |v| deep_sub.call(v, from, to) }
  when Hash   then value.transform_values { |v| deep_sub.call(v, from, to) }
  else value
  end
end

contains = lambda do |value, needle|
  case value
  when String then value.include?(needle)
  when Array  then value.any? { |v| contains.call(v, needle) }
  when Hash   then value.values.any? { |v| contains.call(v, needle) }
  else false
  end
end

dry_run = ENV["DRY_RUN"] == "1"
changed = 0

ActiveRecord::Base.transaction do
  subs.each do |slug, column, from, to|
    record = Topic.find_by!(slug: slug)
    value = record.public_send(column)
    next if contains.call(value, to) && !contains.call(value, from)
    raise "STALE_TEXT_NOT_FOUND #{slug}/#{column}: #{from[0, 40]}" unless contains.call(value, from)

    record.update_columns(column => deep_sub.call(value, from, to), updated_at: Time.current) unless dry_run
    changed += 1
  end
  puts "  [g37-batch4] #{dry_run ? 'DRY_RUN ' : ''}changes=#{changed}"
  raise ActiveRecord::Rollback if dry_run
end
