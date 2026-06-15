# frozen_string_literal: true

#
# 감사사례 checkpoints 백필 (2026-06-15) — 빈-checkpoint 8건 (예산·복무 클러스터)
#
# 배경: 데이터 완결성 감사 — published 191건 中 checkpoints 빈 것 111건(58%).
#       예산 집행/복무(겸직·복직) 클러스터부터 보강. (조회수 균일하여 주제 묶음 우선)
#
# 원칙(게이트 안전): 새 법령 주장 0. 각 사례가 이미 보유한 검증된 lesson/issue의
#       예방 항목을 실행 가능한 체크포인트로 재구성. checkpoints 스키마 = Array of
#       {icon(material-symbols), title, desc}. (기존 audit_checkpoint_backfill_*.rb 와 동일)

CHECKPOINTS = {
  # === 예산 집행 클러스터 ===
  "budget-execution-before-approval" => [
    { "icon" => "schedule",   "title" => "지출원인행위는 집행 전",   "desc" => "지방회계법 §29 — 계약·품의 등 지출 원인행위는 예산 범위 내에서 반드시 집행 전에 한다." },
    { "icon" => "block",      "title" => "사후 소급 처리 금지",     "desc" => "'급하니 먼저 받고 나중에 처리'는 위법. 계약 미체결 상태의 용역 수령은 법적 보호를 받지 못한다." },
    { "icon" => "fact_check", "title" => "날짜 일치 확인",          "desc" => "세금계산서와 지출결의 날짜 불일치는 감사에서 즉시 적발된다." }
  ],
  "budget-transfer-without-council-approval" => [
    { "icon" => "call_split", "title" => "전용·이용 구분",          "desc" => "세항·목 간 이동은 전용(결재권자 승인), 항 이상 이동은 이용(지방의회 의결)으로 절차가 다르다." },
    { "icon" => "pin",        "title" => "과목 코드로 판정",        "desc" => "과목 코드 셋째 자리(항)가 다르면 이용=의회 의결, 같고 넷째 자리(세항)만 다르면 전용=단체장 승인." },
    { "icon" => "gavel",      "title" => "의결권 침해 주의",        "desc" => "항 간 이동을 전용으로 처리하면 의회 의결권 침해로 지적된다." }
  ],
  "contingency-fund-misuse" => [
    { "icon" => "help",       "title" => "예측 가능성 자가점검",    "desc" => "편성 당시 예상했거나 매년 반복되는 지출은 예비비 대상이 아니다." },
    { "icon" => "swap_horiz", "title" => "전용·추경 우선 검토",     "desc" => "추경 편성 여유가 있으면 추경이 우선. 다른 항목 잔액은 전용으로 대응한다." },
    { "icon" => "event_repeat", "title" => "반복지출은 본예산 증액", "desc" => "제설비 등 연례 발생 비용은 다음 해 예산에 증액 편성한다." }
  ],

  # === 복무: 복직·신고 클러스터 ===
  "silmu-2026-reinstatement-late-notice" => [
    { "icon" => "notifications_active", "title" => "사유 소멸 30일 내 신고", "desc" => "휴직 기간이 안 끝나도 사유가 소멸하면 30일 이내 복직 신고 의무가 발생한다(지방공무원법 §65②)." },
    { "icon" => "warning",  "title" => "미신고 = 무단결근",  "desc" => "사유 소멸 후 임의 휴직 연장은 무단결근으로 간주되어 징계 사유가 된다." },
    { "icon" => "report",   "title" => "모호하면 일단 신고",  "desc" => "사유 소멸 시점이 모호하면 우선 신고해 무단결근 위험을 피한다." }
  ],
  "silmu-2026-reinstatement-expired-no-notice" => [
    { "icon" => "event_available", "title" => "만료 30일 내 = 당연복직", "desc" => "휴직 만료일 30일 이내 복귀신고 시 별도 처분 없이 당연 복직된다(§65③)." },
    { "icon" => "assignment_late",  "title" => "30일 경과 시 별도 처분",  "desc" => "당연 복직 효력 상실 시 임용권자의 별도 복직 명령이 있어야 하며 그 사이는 무단결근 위험." },
    { "icon" => "description", "title" => "구두 표명은 신고 아님", "desc" => "전화·구두 의사 표명은 정식 신고로 인정되지 않는다." }
  ],

  # === 복무: 겸직·영리 클러스터 ===
  "silmu-2026-concurrent-unauthorized" => [
    { "icon" => "verified_user", "title" => "비영리·무보수도 사전허가", "desc" => "지방공무원법 §56 — 영리·비영리·보수 유무 무관하게 소속 기관장 사전 허가가 필수." },
    { "icon" => "account_balance", "title" => "소속 기관장 확인",      "desc" => "지방은 단체장 또는 의장, 국가는 직급별 임용(제청)권자가 허가권자." },
    { "icon" => "block",         "title" => "사후 허가는 무효",       "desc" => "사후에 허가를 받아도 위반 사실은 해소되지 않는다." }
  ],
  "silmu-2026-concurrent-for-profit-business" => [
    { "icon" => "do_not_disturb_on", "title" => "영리업무 4유형 원천금지", "desc" => "지방공무원 복무규정 §10 — 4유형 영리업무는 허가로 면제되지 않는 원천 금지 대상." },
    { "icon" => "groups",     "title" => "차명·가족명의도 적발",   "desc" => "가족 명의를 빌린 실질 경영(임원 활동)도 영리업무 위반으로 본다." },
    { "icon" => "checklist",  "title" => "4유형 자가점검",         "desc" => "스스로 경영/사기업 임원/직무관련 투자/계속적 재산 이득 업무 해당 여부를 점검한다." }
  ]
}.freeze

puts "== 감사사례 checkpoints 백필 (2026-06-15) =="
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
