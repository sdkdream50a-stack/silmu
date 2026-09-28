# Topic contingency-fund — 예비비 사용 요건의 근거로 적힌 «지방재정법 시행령 제65조» 정정(2026-09-29)
#
# 시행령 제65조는 «재정분석 및 재정점검»(행정안전부장관의 재정보고서 분석·재정위험 점검) 조문으로 예비비와 무관하다.
# 예비비의 법률 근거는 지방재정법 제43조다. 제43조제1항은 «예측할 수 없는 예산 외의 지출 또는 예산 초과 지출에 충당»만 정하고,
# 긴급성·전용/이용 불가·목적 적합성은 법·시행령 조문에 없다(시행령의 예비비 조문은 제48조 계상 제한·제56조제3항 배정뿐)
# → 조문 번호는 확인된 제43조제1항으로 바꾸고, 나머지 요건은 «실무 검토 사항»으로 중립 서술한다.
# 원문: 지방재정법 [MST 283145, 시행 2026. 7. 1.] 제43조
#       https://www.law.go.kr/DRF/lawService.do?OC=test&target=law&MST=283145&type=XML
#       지방재정법 시행령 [MST 281539, 시행 2026. 1. 2.] 제65조(재정분석 및 재정점검)·제48조·제56조
#       https://www.law.go.kr/DRF/lawService.do?OC=test&target=law&MST=281539&type=XML
# 운영 옛 값: https://silmu.kr/topics/contingency-fund 익명 GET(2026-09-29) — FAQ 답변(본문·FAQPage JSON-LD)·요약 카드 note 2곳.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929040000_contingency_fund_article_fix.rb})"'
#   → 기대: changes=2 (Topic contingency-fund faqs 1 · quick_stats 1)
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화) → 재실행 시 changes=0
#
# 동작: 필드별 old 가 정확히 1회 있어야 바꾼다. 이미 new 이면 건너뛴다. 하나라도 어긋나면 전체 롤백.
# DRY_RUN=1 이면 바꿀 필드만 출력하고 쓰지 않는다. view_count 는 건드리지 않는다. 롤백: 같은 표의 new → old 역적용.

slug = "contingency-fund"

edits = [
  [ "faqs",
    "예측 불가능성, 긴급성, 기존 예산의 전용·이용으로 해결 불가, 목적 적합성 요건을 모두 충족해야 사용할 수 있습니다(지방재정법 시행령 제65조).",
    "지방재정법 제43조제1항은 예비비를 「예측할 수 없는 예산 외의 지출 또는 예산 초과 지출」에 충당하도록 정하고 있습니다. 긴급성, 기존 예산의 전용·이용으로 해결 불가, 목적 적합성은 실무에서 함께 검토하는 사항입니다." ],
  [ "quick_stats",
    "지방재정법 시행령 제65조",
    "지방재정법 제43조제1항(예측할 수 없는 지출) · 그 밖의 요건은 실무 기준" ]
]

count_in = lambda do |value, needle|
  case value
  when String then value.scan(needle).size
  when Array  then value.sum { |v| count_in.call(v, needle) }
  when Hash   then value.values.sum { |v| count_in.call(v, needle) }
  else 0
  end
end

replace_in = lambda do |value, from, to|
  case value
  when String then value.gsub(from) { to }
  when Array  then value.map { |v| replace_in.call(v, from, to) }
  when Hash   then value.transform_values { |v| replace_in.call(v, from, to) }
  else value
  end
end

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  topic = Topic.find_by(slug: slug)
  if topic
    edits.each do |field, old, new|
      value = topic.read_attribute(field)
      next if count_in.call(value, new).positive? && count_in.call(value, old).zero?
      raise "[contingency-fund] fingerprint missing: Topic/#{slug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

      puts "  [contingency-fund] Topic/#{slug} fields_to_change=#{field}"
      changes += 1
      topic.update_columns(field => replace_in.call(value, old, new), updated_at: Time.current) unless dry
    end
  end
end
puts "  [contingency-fund] #{"DRY_RUN " if dry}changes=#{changes}"
