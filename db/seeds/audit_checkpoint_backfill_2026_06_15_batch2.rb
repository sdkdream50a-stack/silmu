# frozen_string_literal: true
#
# 감사사례 checkpoints 백필 (2026-06-15) batch2 — 입찰 클러스터 3건
#
# 배경/원칙: batch1과 동일. 새 법령 주장 0 — 각 사례의 검증된 lesson 의 예방 항목을
#       체크포인트로 재구성. 스키마 = Array of {icon, title, desc}.

CHECKPOINTS = {
  "goe-2021-contract-method-2stage-bidding" => [
    { "icon" => "category",   "title" => "입찰방식 5종 구분",     "desc" => "일반·제한·지명·2단계·협상에 의한 계약을 사업 성격에 맞게 선택한다." },
    { "icon" => "rule",       "title" => "2단계 입찰 적용 사유",  "desc" => "미리 적절한 규격 작성이 곤란한 사업에 2단계(규격·가격 분리) 입찰을 적용한다." },
    { "icon" => "description","title" => "방식은 공고에 명시",    "desc" => "선택한 입찰방식과 적용 사유를 공고에 명시한다." }
  ],
  "goe-2021-bid-announcement-period" => [
    { "icon" => "schedule",   "title" => "종류별 공고기간 준수",  "desc" => "입찰 종류별 법정 공고기간을 준수한다." },
    { "icon" => "location_on","title" => "지역제한 단일 시·도",   "desc" => "지역제한은 납품지 소재 단일 시·도만 가능. '경기,서울' 동시 허용은 위반." },
    { "icon" => "warning",    "title" => "인접 시군 제한 주의",   "desc" => "인접 시군 제한은 소규모 업체 진입을 막아 특정 업체에 유리하게 작용(부정 의혹)." }
  ],
  "sen-2025-school-c-long-term-contract-violation" => [
    { "icon" => "event_repeat","title" => "단순노무 1년 한정",    "desc" => "청소·경비 등 단순 노무 용역은 법적으로 1년 계약 한정. 2년 입찰은 법령 위반." },
    { "icon" => "calendar_month","title" => "매년 새 입찰",        "desc" => "같은 업체가 연속 낙찰돼도 매년 입찰 절차는 별개로 진행한다." },
    { "icon" => "fact_check", "title" => "공고 캘린더 의무화",     "desc" => "노무 용역은 회계연도 시작 전 공고 캘린더로 매년 입찰을 관리한다." }
  ]
}.freeze

puts "== 감사사례 checkpoints 백필 batch2 (2026-06-15) =="
updated = 0
CHECKPOINTS.each do |slug, items|
  ac = AuditCase.find_by(slug: slug)
  unless ac
    puts "  ⚠️  미발견: #{slug} (건너뜀)"
    next
  end
  if ac.checkpoint_list.any?
    puts "  =  이미존재: #{slug} (건너뜀)"
    next
  end
  ac.update!(checkpoints: items)
  updated += 1
  puts "  ✅ #{slug} — #{items.size}개 (#{ac.title.to_s.truncate(34)})"
end
puts "== 완료: #{updated}건 백필 / 총 #{CHECKPOINTS.size}건 =="
