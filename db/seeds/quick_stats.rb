# frozen_string_literal: true

# Sprint Task #4 — TOP 토픽 quick_stats 입력
# 권위자(Schwartz·Tufte) 권고: 검색 의도 매칭을 위한 핵심 수치 노출
# 각 표는 .law-key-fact selector로 speakable cssSelector와 자동 매칭됨
# 출처는 모두 silmu의 BlogLegalVerifier 검증 통과한 법령 1차 사료 기준

QUICK_STATS = {
  # 1. 수의계약 (#1 트래픽 — 862회)
  "private-contract" => [
    { "label" => "공사 (종합)",     "value" => "4억원 이하",      "note" => "추정가격" },
    { "label" => "공사 (전문)",     "value" => "2억원 이하",      "note" => "추정가격" },
    { "label" => "물품·용역",       "value" => "2,000만원 이하",  "note" => "기본 기준" }
  ],

  # 2. 입찰 (#2 트래픽 — 454회)
  "bidding" => [
    { "label" => "공고기간 (일반)",  "value" => "7일 이상",        "note" => "추정가격 1억 이상" },
    { "label" => "공고기간 (긴급)",  "value" => "5일 이상",        "note" => "긴급 사유 명시" },
    { "label" => "낙찰 방식",        "value" => "예정가격 이하 최저가", "note" => "적격심사 가산" }
  ],

  # 3. 여비 (#3 트래픽 — 423회) — 토픽 slug: travel-expense
  "travel-expense" => [
    { "label" => "국내 일비",       "value" => "20,000원/일",     "note" => "공무원 여비규정 별표 2" },
    { "label" => "국내 식비",       "value" => "25,000원/일",     "note" => "3식 합산" },
    { "label" => "숙박비 (정액)",   "value" => "70,000원/일",     "note" => "기타 도시 기준" }
  ],

  # 4. 수의계약 한도 (#8 트래픽 — 254회)
  "private-contract-limit" => [
    { "label" => "종합공사",         "value" => "4억원",           "note" => "추정가격 이하" },
    { "label" => "전문공사",         "value" => "2억원",           "note" => "전기·정보통신·소방" },
    { "label" => "물품·용역",        "value" => "2,000만원",       "note" => "특례기업 5,000만원" }
  ],

  # 5. 수의계약 금액 (#7 트래픽 — 268회)
  "private-contract-amount" => [
    { "label" => "1인 견적",        "value" => "2,000만원 이하",  "note" => "특례기업 5,000만원" },
    { "label" => "2인 이상 견적",   "value" => "한도 이하 구간",  "note" => "최저가 선정" },
    { "label" => "견적서 생략",      "value" => "200만원 이하",    "note" => "시행령 §30 단서" }
  ]
}.freeze

puts "📊 TOP 5 토픽 quick_stats 입력 시작"

QUICK_STATS.each do |slug, stats|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    puts "❌ [#{slug}] 토픽 없음 — 스킵"
    next
  end
  topic.update_column(:quick_stats, stats)
  puts "✅ [#{slug}] #{topic.name} — #{stats.size}개 stats 입력"
end

puts ""
puts "📊 적용 토픽 #{Topic.where.not(quick_stats: nil).where("quick_stats <> '[]'::jsonb").count}건"
