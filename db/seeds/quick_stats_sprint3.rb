# frozen_string_literal: true

# Sprint 3 ATF-01 — quick_stats 백필 (배치 1: 고트래픽 18토픽)
# 목적: 23초 체류(intent mismatch at the fold) 해소. 본문 43% 지점에 매장된 핵심 수치를
#       above-the-fold quick_stats 슬롯으로 표면화한다(show.html.erb:190 기존 슬롯, 신규필드 X).
# 원칙: 각 수치는 이미 BlogLegalVerifier 검증 통과한 운영 토픽 본문에 존재하는 값을 그대로 미러링.
#       (재검증·신규수치 도입 X → 본문과 quick_stats 불일치 방지, 외과적 범위 준수)
# 제외: price-negotiation(20)·emergency-contract(26)는 수치 빈약(절차 위주)으로 품질상 미백필.

QUICK_STATS_SPRINT3 = {
  # 입찰공고 (id:1, 325회) — 공고기간 별표
  "bid-announcement" => [
    { "label" => "공고기간(10억 미만)", "value" => "7일 이상",   "note" => "공사·현장설명 미실시" },
    { "label" => "공고기간(50억~고시금액)", "value" => "30일 이상", "note" => "고시금액 이상은 40일" },
    { "label" => "긴급입찰",            "value" => "5일",        "note" => "사유 명시 시" }
  ],

  # 계약보증금 (id:4, 337회)
  "contract-guarantee-deposit" => [
    { "label" => "계약보증금", "value" => "10% 이상", "note" => "계약금액 기준" },
    { "label" => "입찰보증금", "value" => "5% 이상",  "note" => "입찰금액 기준" },
    { "label" => "하자보증금", "value" => "2~5%",     "note" => "공종별 차등" }
  ],

  # 하자보증 (id:6, 255회) — 공종별 하자담보책임기간
  "defect-warranty" => [
    { "label" => "구조체",        "value" => "5년", "note" => "골조·기초" },
    { "label" => "방수·도로포장", "value" => "3년", "note" => "지붕 포함" },
    { "label" => "도장·미장 등",  "value" => "1년", "note" => "창호·전기·설비는 2년" }
  ],

  # 검수·검사 (id:10, 679회) — 최고 트래픽
  "inspection" => [
    { "label" => "검사 완료",     "value" => "14일 이내",   "note" => "이행완료 통보일부터" },
    { "label" => "대가 지급",     "value" => "5일 이내",    "note" => "청구일부터" },
    { "label" => "검사조서 생략", "value" => "5천만원 이하", "note" => "추정가격 기준" }
  ],

  # 대금지급 (id:13, 367회)
  "payment" => [
    { "label" => "대가 지급",   "value" => "5일 이내",  "note" => "청구일부터" },
    { "label" => "선금 한도",   "value" => "70% 이내",  "note" => "계약금액 기준" },
    { "label" => "하도급 직불", "value" => "15일 이내", "note" => "원수급인 수령 후" }
  ],

  # 1인견적 (id:21, 507회)
  "single-quote" => [
    { "label" => "1인 견적 한도", "value" => "2천만원 이하", "note" => "물품·용역·공사" },
    { "label" => "특례기업",      "value" => "5천만원 이하", "note" => "청년·여성·장애인 등" },
    { "label" => "예정가격",      "value" => "작성 생략 가능", "note" => "2천만원 이하" }
  ],

  # 2인 이상 견적 (id:22, 354회)
  "dual-quote" => [
    { "label" => "물품·용역", "value" => "2천만~1억원", "note" => "2인 견적 의무 구간" },
    { "label" => "안내공고",  "value" => "3일 이상",    "note" => "나라장터·학교장터" },
    { "label" => "전자견적",  "value" => "필수",        "note" => "2천만원 초과 시 G2B" }
  ],

  # 소액수의 (id:25, 240회)
  "small-amount-contract" => [
    { "label" => "종합공사",  "value" => "4억원 이하",  "note" => "추정가격" },
    { "label" => "전문공사",  "value" => "2억원 이하",  "note" => "기타공사 1.6억" },
    { "label" => "물품·용역", "value" => "2천만원 이하", "note" => "청년창업 5천만원·소기업 등 1억원" }
  ],

  # 예산이월 (id:28, 279회)
  "budget-carryover" => [
    { "label" => "이월명세서 통보", "value" => "5일 이내", "note" => "회계연도 종료 후" },
    { "label" => "계속비 설정",     "value" => "5년 이내", "note" => "시행규칙 제12조" },
    { "label" => "재이월",          "value" => "불가",     "note" => "다음 연도 1회 한정" }
  ],

  # 선금(선급금) (id:30, 598회) — 용역 요율 본문 불일치로 공사·학술연구만 노출
  "advance-payment" => [
    { "label" => "공사·물품·제조", "value" => "70% 이내",     "note" => "계약금액 기준" },
    { "label" => "학술·연구용역",  "value" => "50% 이내",     "note" => "계약금액 기준" },
    { "label" => "정산",           "value" => "기성 비례 공제", "note" => "기성청구액÷계약금액×선금" }
  ],

  # 낙찰하한율 (id:38, 475회)
  "lowest-bid-rate" => [
    { "label" => "현행 하한율", "value" => "89.745%", "note" => "2026.1.2 이후" },
    { "label" => "이전 하한율", "value" => "87.745%", "note" => "2025.12.31까지" },
    { "label" => "물품·용역",   "value" => "미적용",   "note" => "공사에만 적용" }
  ],

  # 가족수당 (id:74, 221회)
  "family-allowance" => [
    { "label" => "배우자",        "value" => "월 4만원",    "note" => "" },
    { "label" => "자녀",          "value" => "3·7·11만원", "note" => "첫째·둘째·셋째↑" },
    { "label" => "부양 직계존속", "value" => "월 2만원",    "note" => "소득요건 충족 시" }
  ],

  # 여비정산 (id:79, 252회)
  "travel-expense-settlement" => [
    { "label" => "일비",   "value" => "2만원/일",    "note" => "직급 공통" },
    { "label" => "식비",   "value" => "2.5만원/일",  "note" => "5급 이하 2만원" },
    { "label" => "숙박비", "value" => "실비(상한 내)", "note" => "영수증 정산" }
  ],

  # 국내출장 여비 (id:80, 318회)
  "domestic-travel-allowance" => [
    { "label" => "일비",       "value" => "2만원/일",   "note" => "직급 공통" },
    { "label" => "식비",       "value" => "2.5만원/일", "note" => "5급 이하 2만원" },
    { "label" => "숙박비 상한", "value" => "7만원/일",   "note" => "5급 이하 6만원" }
  ],

  # 자가용 출장 여비 (id:81, 482회) — 유류비는 법정 정액 아님(기관 단가)으로 정직하게 표기
  "vehicle-travel-allowance" => [
    { "label" => "유류비",     "value" => "기관 단가×거리", "note" => "통상 km당 약 220원" },
    { "label" => "통행료·주차", "value" => "실비 정산",     "note" => "주차비 원칙 미지급" },
    { "label" => "사전 절차",   "value" => "기관장 승인",   "note" => "미승인 시 지급거부" }
  ],

  # 병가 (id:84, 283회)
  "sick-leave" => [
    { "label" => "일반 병가",   "value" => "연 60일",  "note" => "" },
    { "label" => "공무상 병가", "value" => "연 180일", "note" => "" },
    { "label" => "진단서",      "value" => "7일째부터", "note" => "연간 누적 기준" }
  ],

  # 육아휴직 (id:85, 229회)
  "parental-leave" => [
    { "label" => "최대 기간",       "value" => "자녀당 3년", "note" => "만 12세·초6 이하" },
    { "label" => "수당(1~3개월)",   "value" => "봉급 100%",  "note" => "상한 250만원" },
    { "label" => "배우자 출산휴가", "value" => "10일",       "note" => "출생 90일 내 사용" }
  ],

  # 특별휴가 (id:87, 240회) — 경조사 별표
  "special-leave" => [
    { "label" => "본인 결혼",   "value" => "5일",  "note" => "" },
    { "label" => "배우자 출산", "value" => "10일", "note" => "출생 90일 내 사용" },
    { "label" => "경조사 사망", "value" => "5일",  "note" => "배우자·부모, 자녀·형제는 3일" }
  ]
}.freeze

puts "📊 Sprint 3 quick_stats 백필 시작 (#{QUICK_STATS_SPRINT3.size}개 토픽)"

applied = 0
QUICK_STATS_SPRINT3.each do |slug, stats|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    puts "❌ [#{slug}] 토픽 없음 — 스킵"
    next
  end
  topic.update_column(:quick_stats, stats)
  applied += 1
  puts "✅ [#{slug}] #{topic.name} — #{stats.size}개"
end

puts ""
puts "📊 백필 완료: #{applied}/#{QUICK_STATS_SPRINT3.size}건"
total = Topic.where("quick_stats <> '[]'::jsonb").count
puts "📊 전체 quick_stats 보유 토픽: #{total}건"
