# frozen_string_literal: true
#
# 토픽 fold intent 감사 (2026-06-05) — answer-first 요약 재작성
#
# 배경: 상위 조회 토픽의 above-fold Quick Answer(@topic.summary)가 검색의도를
#       첫 문장에 답하지 못하고 정의/범위서술("~를 안내합니다")에 그쳐
#       체류 23초(측정된 C등급, intent mismatch at fold)의 원인.
#
# 원칙: 새 법령 주장 0. 각 토픽이 이미 보유한 검증된 quick_stats 값만
#       첫 문장으로 끌어올림(answer-first). update!로 updated_at 갱신 →
#       topic_md 캐시 키(updated_at) 자동 무효화. 카테고리 카드 truncate(60)
#       첫 60자 의미 완결 확인.

FOLD_SUMMARIES = {
  "single-quote" =>
    "추정가격 2천만원 이하면 1인 견적만으로 수의계약이 가능합니다. 청년·여성·장애인 등 특례기업은 5천만원 이하, 2천만원 이하는 예정가격 작성도 생략할 수 있습니다.",
  "private-contract" =>
    "경쟁입찰 없이 특정인과 체결하는 계약으로, 추정가격 기준 물품·용역 2천만원·종합공사 4억원·전문공사 2억원 이하에서 가능합니다. 금액과 사유에 따라 1인 또는 2인 견적으로 구분합니다.",
  "travel-expense" =>
    "공무원 국내 출장 여비는 일비 2만원, 식비 2.5만원, 숙박비 정액 7만원(기타 도시)이 기준입니다. 출장 종류별 여비 지급 기준과 청구 절차를 정리했습니다.",
  "inspection" =>
    "검사는 이행완료 통보일부터 14일 이내, 대가 지급은 청구일부터 5일 이내에 해야 합니다. 물품 검수·기성·준공검사 절차와 검수조서 작성법(추정가격 5천만원 이하 생략 가능)을 안내합니다.",
  "bidding" =>
    "지방자치단체 경쟁입찰 공고기간은 일반 7일·긴급 5일 이상이며, 낙찰은 예정가격 이하 최저가(적격심사 가산)로 결정됩니다. 입찰 종류·참가자격·낙찰자 결정 절차를 정리했습니다.",
  "price-negotiation" =>
    "수의계약에서 견적가격이 예정가격을 초과하거나 부적정할 때 가격만 1회 협상(규격·수량 변경 불가)합니다. 시담 후 예정가격 이하 최저가 견적자로 결정하며 시담조서 작성이 필수입니다."
}.freeze

puts "== 토픽 fold 요약 재작성 (2026-06-05) =="
updated = 0
FOLD_SUMMARIES.each do |slug, new_summary|
  topic = Topic.find_by(slug: slug)
  unless topic
    puts "  ⚠️  미발견: #{slug} (건너뜀)"
    next
  end
  old = topic.summary.to_s
  if old == new_summary
    puts "  =  변경없음: #{slug}"
    next
  end
  topic.update!(summary: new_summary)
  updated += 1
  puts "  ✅ #{slug} (#{topic.name})"
  puts "       이전: #{old.truncate(50)}"
  puts "       이후: #{new_summary.truncate(50)}"
end
puts "== 완료: #{updated}건 변경 / 총 #{FOLD_SUMMARIES.size}건 =="
