# frozen_string_literal: true

#
# 감사사례 checkpoints 백필 2차 (2026-06-05) — 조회수 상위 빈건 14건
#
# 1차(12건)에 이어 다음 조회수 구간(56~78뷰). 게이트 안전: 새 법령주장 0 —
# 각 사례 기보유 검증 lesson/issue 예방항목을 {icon,title,desc}로 재구성.

CHECKPOINTS = {
  "performance-bonus-score-manipulation" => [
    { "icon" => "balance",      "title" => "평가 객관성 유지", "desc" => "성과상여금은 객관적 근무성적에 따라 지급하며 점수 임의 조작은 중징계 대상이다." },
    { "icon" => "groups",       "title" => "연쇄 피해 인식",   "desc" => "점수 조작은 정당하게 평가받을 다른 직원의 등급 하락으로 이어진다." },
    { "icon" => "receipt_long", "title" => "부당 이득 환수",   "desc" => "조작으로 과다 수령한 상여금은 환수 대상이 된다." }
  ],
  "disciplinary-action-request-delay" => [
    { "icon" => "campaign", "title" => "비위 인지 즉시 보고", "desc" => "비위 사실 인지 후 징계의결 요구를 지연하면 직무유기에 해당할 수 있다." },
    { "icon" => "timer",    "title" => "징계 시효 관리",     "desc" => "의결 요구 지연은 징계 시효 소멸 위기를 초래한다." },
    { "icon" => "block",    "title" => "개인적 처리 금지",   "desc" => "상급자라도 비위를 개인적으로 덮으면 더 큰 책임을 진다." }
  ],
  "holiday-bonus-pre-retirement-payment" => [
    { "icon" => "event_available", "title" => "기준일 재직자 확인",  "desc" => "명절 당일 기준 재직자 명단을 최종 확인한 후 지급한다." },
    { "icon" => "person_off",      "title" => "기준일 전 퇴직자 제외", "desc" => "기준일 이전 퇴직 효력자는 명절 휴가비 대상에서 제외한다." },
    { "icon" => "receipt_long",    "title" => "과다 지급 시 환수",  "desc" => "지급 요건 미충족 지급분은 환수 대상이다." }
  ],
  "secondment-return-delay" => [
    { "icon" => "event",       "title" => "파견 종료일 준수", "desc" => "발령 문서에 명시된 파견 기한까지 원소속 복귀가 원칙이다." },
    { "icon" => "description",  "title" => "연장은 공식 절차", "desc" => "파견 연장은 구두 요청이 아닌 공식 연장 절차를 거쳐야 한다." }
  ],
  "sen-2025-school-y-facility-multi-violation" => [
    { "icon" => "schedule",      "title" => "공사기간 1개월 임계", "desc" => "공사기간이 1개월 미만이면 건강·연금보험료를 계상할 수 없다." },
    { "icon" => "fact_check",    "title" => "준공 증빙 확인",    "desc" => "준공 시 계약자의 지급 증빙서류를 확인하고 대금을 지급한다." },
    { "icon" => "edit_document", "title" => "설계변경 즉시 절차", "desc" => "설계변경은 사후 처리하지 말고 변경 시점에 즉시 절차에 진입한다." }
  ],
  "sen-2025-school-s-disaster-prevention" => [
    { "icon" => "warning",     "title" => "연장 시 1개월 재판정",  "desc" => "공사기간 연장 시점에 1개월 임계를 다시 판정한다." },
    { "icon" => "engineering", "title" => "재해예방 기술지도 계약", "desc" => "1개월 이상 공사는 재해예방 기술지도 계약을 체결한다." },
    { "icon" => "gavel",       "title" => "누락 시 책임 가중",   "desc" => "기술지도 누락 시 산재 사고에서 학교장 형사책임이 가중된다." }
  ],
  "annual-leave-compensation-double-payment" => [
    { "icon" => "calculate",     "title" => "미사용 연가만 보상", "desc" => "연가보상비는 실제 사용하지 않은 미사용 연가 일수에만 지급한다." },
    { "icon" => "remove_circle", "title" => "사용일수 차감",     "desc" => "연중 사용한 연가는 차감하고 잔여 일수를 기준으로 산정한다." }
  ],
  "sen-2025-school-c-electrical-separate-order" => [
    { "icon" => "call_split",  "title" => "전기공사 분리발주", "desc" => "전기공사는 법적으로 분리발주가 강제되며 통합발주할 수 없다." },
    { "icon" => "engineering", "title" => "유자격 시공 확인",  "desc" => "무자격 전기 시공은 화재·감전 사고 시 책임으로 직결된다." },
    { "icon" => "assignment",  "title" => "계약 단계에서 분리", "desc" => "시공이 아닌 계약 단계에서 전기공사를 분리해야 한다." }
  ],
  "goe-2021-retirement-pension-mismanagement" => [
    { "icon" => "savings",      "title" => "세입세출외현금 처리", "desc" => "DB형 퇴직적립금은 세입세출외현금으로 분리 보관·세입처리한다." },
    { "icon" => "event_repeat", "title" => "매년 정산",        "desc" => "DB형은 매년 적립금을 정산하고 부족분을 추가 적립한다." }
  ],
  "parental-leave-benefit-double-receipt" => [
    { "icon" => "campaign", "title" => "복직 즉시 신고",   "desc" => "복직·조기복직·퇴직 시 즉시 고용센터에 신고한다." },
    { "icon" => "block",    "title" => "미신고 시 부정수급", "desc" => "미신고로 급여가 계속 지급되면 부정 수급으로 전액 환수된다." }
  ],
  "sen-2025-school-c-facility-design-document" => [
    { "icon" => "description", "title" => "설계도서 작성",   "desc" => "2천만원 초과 시설공사는 자격자가 작성한 설계도서가 결재 진입 요건이다." },
    { "icon" => "block",       "title" => "'1식' 견적 금지", "desc" => "'1식' 견적서는 규격·수량 확인이 불가해 감독·검사를 막는다." }
  ],
  "sen-2025-school-s-supply-direct-prod-cert" => [
    { "icon" => "verified",   "title" => "직접생산확인 별도 검증", "desc" => "수의계약이라도 중기간 경쟁제품은 직접생산확인이 별도 의무다." },
    { "icon" => "checklist",  "title" => "경쟁제품 여부 확인",   "desc" => "가구·문구 등 중기간 경쟁제품 풀(중기부 고시)을 사전 확인한다." },
    { "icon" => "fact_check", "title" => "1천만원 이상 결재선 점검", "desc" => "1천만원 이상 물품구매 결재선에 경쟁제품·증명서 확인을 넣는다." }
  ],
  "sen-2025-school-d-split-private-contract" => [
    { "icon" => "call_split", "title" => "단일 사업 분할 금지", "desc" => "2천만원 초과 단일 사업을 시기적으로 쪼개면 합산 후 적발된다." },
    { "icon" => "search",     "title" => "3요소 점검",        "desc" => "동일 업체·동일 시기·동일 목적 중 2개 이상 일치하면 분할로 간주된다." },
    { "icon" => "verified",   "title" => "초과 시 2인 견적",   "desc" => "2천만원 초과는 G2B로 2인 이상 견적서를 제출받는다." }
  ],
  "goe-2021-overtime-allowance-mispayment" => [
    { "icon" => "timer",     "title" => "정액분 15일 기준", "desc" => "정액분은 출근 근무일수 15일 이상이어야 하며 미만 시 감액한다." },
    { "icon" => "block",     "title" => "중복 보상 금지",   "desc" => "방과후 수업 등 다른 방법으로 보상받은 시간은 시간외수당과 중복 지급할 수 없다." },
    { "icon" => "calculate", "title" => "1시간 공제 후 합산", "desc" => "시간외근무는 1시간 공제 후 4시간 이내 분 단위로 합산한다." }
  ]
}.freeze

puts "== 감사사례 checkpoints 백필 2차 (2026-06-05) =="
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
  puts "  ✅ #{slug} — #{items.size}개 (#{ac.title.truncate(34)})"
end
puts "== 완료: #{updated}건 백필 / 총 #{CHECKPOINTS.size}건 =="
