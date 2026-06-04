# frozen_string_literal: true
#
# 감사사례 checkpoints 백필 (2026-06-05) — 조회수 상위 빈-checkpoint 12건
#
# 배경: Phase0 실측 — published 257건 中 checkpoints 빈 것 139건(54%).
#       단 감사사례 전건 유기 트래픽 존재(평균68·최대341). 조회수 상위 빈 건부터.
#
# 원칙(게이트 안전): 새 법령 주장 0. 각 사례가 이미 보유한 검증된 lesson/issue의
#       예방 항목을 실행 가능한 체크포인트로 재구성. checkpoints 스키마 = Array of
#       {icon(material-symbols), title, desc}. checkpoint_list가 배열/문자열 모두 파싱.

CHECKPOINTS = {
  "budget-execution-wrong-account" => [
    { "icon" => "fact_check",    "title" => "과목·부서 교차 확인", "desc" => "지출결의서 작성 후 예산 과목 코드와 집행 부서명을 반드시 대조한다." },
    { "icon" => "verified_user", "title" => "결재권자 최종 점검",  "desc" => "결재 단계에서 과목 코드 적정성을 한 번 더 확인한다." },
    { "icon" => "warning",       "title" => "이중 차감 이상 감지", "desc" => "동일 금액이 두 부서에서 동시에 차감되면 즉시 오집행을 의심한다." },
    { "icon" => "smart_toy",     "title" => "e-호조 자동완성 활용", "desc" => "과목 코드 자동 완성 기능으로 수기 입력 오류를 줄인다." }
  ],
  "year-end-settlement-duplicate-deduction" => [
    { "icon" => "person_search", "title" => "1인 1공제 원칙",     "desc" => "동일 부양가족 기본공제는 소득자 1명만 적용된다(형제자매 중복 불가)." },
    { "icon" => "groups",        "title" => "가족 간 공제 조율",  "desc" => "같은 부모를 부양하는 형제자매가 있으면 누가 공제받는지 사전 확인한다." },
    { "icon" => "receipt_long",  "title" => "중복 시 추징 주의",  "desc" => "이중 공제가 적발되면 과세관청 추징 대상이 된다." }
  ],
  "retirement-allowance-service-period-error" => [
    { "icon" => "badge",      "title" => "군복무 기간 산입 주의", "desc" => "임용 전 군복무는 별도 합산 신청 없이는 재직기간에 산입할 수 없다." },
    { "icon" => "fact_check", "title" => "인사기록카드 대조",     "desc" => "재직기간 산정 전 임용·휴직·공백 기간을 인사기록카드와 대조한다." },
    { "icon" => "calculate",  "title" => "산정 후 재검산",        "desc" => "퇴직수당 산정 후 재직기간 합산 내역을 재검산해 과다 지급을 막는다." }
  ],
  "welfare-point-cash-conversion" => [
    { "icon" => "block",      "title" => "현금화 금지",        "desc" => "복지포인트는 현금 등가물이 아니며 환전·양도·현금성 상품권 구매가 금지된다." },
    { "icon" => "storefront", "title" => "가맹점 정기 점검",   "desc" => "현금화가 가능한 가맹점 이용 여부를 정기적으로 점검한다." },
    { "icon" => "gavel",      "title" => "위반 시 환수·징계",  "desc" => "용도 외 사용은 포인트 환수 및 징계 대상이 된다." }
  ],
  "official-leave-false-reason" => [
    { "icon" => "checklist",   "title" => "공가 사유 한정 열거", "desc" => "복무규정에 열거된 사유에 해당하지 않으면 공가로 처리할 수 없다." },
    { "icon" => "schedule",    "title" => "사유 종료 시 복귀",   "desc" => "공가 사유가 끝나면 지체 없이 정상 근무로 전환한다." },
    { "icon" => "description",  "title" => "증빙 확보",          "desc" => "증인 출석·예비군 훈련 등 공가 사유의 증빙 서류를 보관한다." }
  ],
  "special-leave-holiday-miscalculation" => [
    { "icon" => "event",     "title" => "근무일 기준 산정",   "desc" => "경조사 특별휴가는 토·일·공휴일을 제외한 근무일 기준으로 산정한다." },
    { "icon" => "calculate", "title" => "부여 전 일수 재확인", "desc" => "휴가 부여 전 경조사 종류별 법정 일수와 근무일을 다시 확인한다." }
  ],
  "leave-of-absence-employment-unreported" => [
    { "icon" => "work_off", "title" => "휴직 중 의무 지속",     "desc" => "휴직 중에도 품위 유지·비밀 준수 등 직무상 의무는 계속 적용된다." },
    { "icon" => "campaign", "title" => "취업·영리행위 신고",    "desc" => "휴직 중 타 기관·업체 취업이나 영리행위는 임용권자에게 신고해야 한다." }
  ],
  "sick-leave-days-exceeded" => [
    { "icon" => "sick",        "title" => "연 60일 한도",        "desc" => "일반 병가는 진단서 제출 시 연 60일이 한도다." },
    { "icon" => "description", "title" => "진단서 없는 병가 6일", "desc" => "진단서 없는 병가는 연 6일이며 일반 병가에 포함된다." },
    { "icon" => "swap_horiz",  "title" => "한도 초과 시 연가",   "desc" => "병가 한도를 넘으면 연가로 처리해 보수 부당 지급을 막는다." }
  ],
  "sen-2025-school-i-split-private-disability" => [
    { "icon" => "call_split", "title" => "통합 한도 인식",     "desc" => "장애인·여성기업 5천만원은 통합 한도로, 동일 사업 분할 시 무력화된다." },
    { "icon" => "search",     "title" => "분할 흔적 점검",     "desc" => "단일 설계서·동일 도면·동일 시점 발주는 분할 수의로 적발된다." },
    { "icon" => "verified",   "title" => "5천만 초과 2인 견적", "desc" => "5천만원 초과는 G2B로 2인 이상 견적서를 제출받아야 한다." }
  ],
  "sen-2025-school-v-facility-split-private" => [
    { "icon" => "call_split",  "title" => "단일사업 분할 금지",  "desc" => "단일 공사를 쪼개 1인 수의계약하는 것은 적발 대상이다." },
    { "icon" => "price_check", "title" => "예정가 임의조정 금지", "desc" => "예정가격은 설계금액·시장조사·관급자재를 종합 산정하며 임의 인하는 위반이다." },
    { "icon" => "search",      "title" => "격차 점검",          "desc" => "설계금액과 예정가의 격차는 감사관이 즉시 확인한다." }
  ],
  "family-allowance-ineligible-payment" => [
    { "icon" => "campaign",     "title" => "변동 즉시 신고",     "desc" => "배우자 취업 등 수급 자격 변동 사유는 발생 즉시 신고한다." },
    { "icon" => "fact_check",   "title" => "부양요건 정기 확인", "desc" => "가족수당 수급자의 부양가족 요건을 정기적으로 점검한다." },
    { "icon" => "receipt_long", "title" => "과다 지급 시 환수",  "desc" => "자격 상실 후 지급분은 환수 대상이 된다." }
  ],
  "information-disclosure-delay" => [
    { "icon" => "schedule",  "title" => "10일 처리 기한",   "desc" => "정보공개 청구는 접수일부터 10일 이내 공개 여부를 결정한다." },
    { "icon" => "more_time", "title" => "연장은 1회 10일",  "desc" => "부득이한 경우 10일 범위에서 1회 연장하며 사유를 통지한다." },
    { "icon" => "gavel",     "title" => "비공개 사유 명시", "desc" => "비공개 결정은 법 제9조의 구체적 법령 근거를 명시해야 한다." }
  ]
}.freeze

puts "== 감사사례 checkpoints 백필 (2026-06-05) =="
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
  puts "  ✅ #{slug} — #{items.size}개 (#{ac.title.truncate(36)})"
end
puts "== 완료: #{updated}건 백필 / 총 #{CHECKPOINTS.size}건 =="
