# frozen_string_literal: true
#
# AEO Sprint3 quick_stats 백필 — 배치3 (예산·회계 안정조문 10토픽)
# 2026-06-03. quick_stats = [{label,value,note}] 배열(뷰 show.html.erb:190 렌더, category 미사용).
# 값은 운영 DB의 FAQ 백필(배치5)에서 검증한 **안정 법령값**만 사용
# (연도변동 단가·기관별 상이 기준 제외, 조문 고정 율·기한·한도·절차만).
#  근거: 지방재정법 §41·§45·§47·§49·§50·§60의2 / 지방회계법 §29·§31·§32·§44·§46 /
#        보조금법 §10·§30·§31·§40 / 회계관계직원책임법 §4 / 감사원법 §36 /
#        정보공개법 §9·§11·§14·§18(이의신청 30일·기관 7일=korean-law 재확인) /
#        초중등교육법 §30의2 / 지자체 회계기준 규칙 §4.
# 정합성 회피: ① budget-item-standard 비품 10만원=법령 고정값 아님→조문 구조만 사용
#             ② national-subsidy 기준보조율=사업별 상이→율 제외·제도 구조만
#             ③ supplementary-budget 연 2~3회=법령값 아님→note 처리, value는 "제한 없음".
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_quick_stats_backfill_2026_06_03_batch3.rb})"'

qs_by_slug = {
  "supplementary-budget" => [
    { "label" => "편성 근거", "value" => "예산 성립 후 생긴 사유", "note" => "지방재정법 제45조" },
    { "label" => "편성 횟수", "value" => "법적 제한 없음", "note" => "통상 연 2~3회" },
    { "label" => "편성 절차", "value" => "당초예산과 동일(편성 → 의회 심의·의결)", "note" => "지방자치법 제144조" },
    { "label" => "긴급 소요", "value" => "예비비 선사용 후 추경 정산", "note" => "지방재정법 제43조" }
  ],
  "national-subsidy" => [
    { "label" => "부정 수급 벌칙", "value" => "10년 이하 징역 또는 1억원 이하 벌금", "note" => "보조금 관리에 관한 법률 제40조" },
    { "label" => "교부결정 취소", "value" => "다른 용도 사용·법령 위반 시 반환 명령", "note" => "보조금법 제31조·제33조" },
    { "label" => "기준보조율", "value" => "사업별 법정 비율 + 재정자주도 차등", "note" => "보조금법 제10조·제10조의2(율은 사업별 상이)" },
    { "label" => "정산 의무", "value" => "사업 완료 시 실적 보고", "note" => "보조금법 제30조" }
  ],
  "budget-transfer" => [
    { "label" => "이용(移用)", "value" => "장·관·항 간 — 지방의회 의결", "note" => "지방재정법 제47조" },
    { "label" => "전용(轉用)", "value" => "세항·목 간 — 단체장 승인", "note" => "지방재정법 제49조" },
    { "label" => "이체", "value" => "기관 통폐합·직제 개편 시", "note" => "조례 개정 또는 행안부 승인" },
    { "label" => "전용 한계", "value" => "의회 삭감 사업 우회 배정 금지", "note" => "지방재정법 제49조 제1항 단서" }
  ],
  "budget-lapse" => [
    { "label" => "명시이월", "value" => "미리 의회 의결 후 다음 연도 이월", "note" => "지방재정법 제50조 제1항" },
    { "label" => "사고이월 사유", "value" => "법정 4가지 사유에 한함", "note" => "지방재정법 제50조 제2항(내부 지연은 불가)" },
    { "label" => "재이월(이중이월)", "value" => "원칙 금지", "note" => "계속비만 예외" },
    { "label" => "회계연도 독립", "value" => "원칙(이월은 법정 예외)", "note" => "지방재정법 제7조" }
  ],
  "accounting-officers" => [
    { "label" => "변상책임 요건", "value" => "고의 또는 중대한 과실", "note" => "회계관계직원 등의 책임에 관한 법률 제4조" },
    { "label" => "경과실", "value" => "감면 가능", "note" => "고의·중과실은 원칙 전액 변상" },
    { "label" => "재심의 청구", "value" => "변상판정서 받은 날부터 3개월 이내", "note" => "감사원법 제36조" },
    { "label" => "직무 분리", "value" => "재무관·지출원·출납원 분리", "note" => "지방회계법 제46조·제36조" }
  ],
  "budget-item-standard" => [
    { "label" => "예산 과목 체계", "value" => "분야·부문·정책·단위·세부사업·목", "note" => "지방재정법 제41조" },
    { "label" => "목적 외 사용", "value" => "금지", "note" => "지방재정법 제47조" },
    { "label" => "목 간 이동", "value" => "전용 절차 필요", "note" => "지방재정법 제49조" },
    { "label" => "위반 시", "value" => "감사 지적·징계·변상 책임", "note" => "목 잘못 집행 = 제47조 위반" }
  ],
  "local-government-accounting" => [
    { "label" => "법적 근거", "value" => "발생주의·복식부기 재무제표 의무", "note" => "지방재정법 제60조의2" },
    { "label" => "재무제표 구성", "value" => "4종 + 주석", "note" => "재정상태표·재정운영표·순자산변동표·현금흐름표" },
    { "label" => "회계처리 원칙", "value" => "발생주의(거래 발생 시점 인식)", "note" => "지자체 회계기준 규칙 제4조" },
    { "label" => "현금주의 병행", "value" => "세입·세출 결산은 현금주의 유지", "note" => "재무제표와 병행 운영" }
  ],
  "information-disclosure" => [
    { "label" => "공개결정 기한", "value" => "청구 받은 날부터 10일 이내", "note" => "정보공개법 제11조(1회 10일 연장 가능)" },
    { "label" => "이의신청", "value" => "30일 이내 신청 / 기관 7일 내 결정", "note" => "정보공개법 제18조" },
    { "label" => "행정심판·소송", "value" => "처분을 안 날부터 90일 이내", "note" => "이의신청 거치지 않아도 가능" },
    { "label" => "비공개 사유", "value" => "법정 8가지 호", "note" => "정보공개법 제9조(부분공개 원칙 제14조)" }
  ],
  "school-budget-compilation" => [
    { "label" => "회계연도", "value" => "3월 1일 ~ 다음 해 2월 말일", "note" => "초중등교육법 제30조의2 제3항(지자체와 상이)" },
    { "label" => "예산안 제출", "value" => "회계연도 시작 30일 전까지 운영위 제출", "note" => "학교운영위원회 심의" },
    { "label" => "결산 제출", "value" => "다음 회계연도 3월 31일 이전 교육감 제출", "note" => "초중등교육법 제30조의2 제5항" },
    { "label" => "확정권", "value" => "학교장(운영위는 심의)", "note" => "심의이지 의결 아님" }
  ],
  "budget-execution" => [
    { "label" => "집행 4단계", "value" => "지출원인행위 → 지출결의 → 지급명령 → 지급", "note" => "지방회계법 제29조" },
    { "label" => "지출원인행위", "value" => "재무관 담당", "note" => "세출예산·계속비 범위 내(지방회계법 제29조)" },
    { "label" => "지출·지급명령", "value" => "지출원 담당", "note" => "지방회계법 제31조·제32조" },
    { "label" => "현금 출납", "value" => "출납원·금고 담당", "note" => "지방회계법 제44조·제38조" }
  ]
}

updated = []
skipped = []
qs_by_slug.each do |slug, qs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    skipped << "#{slug} (NOT FOUND)"
    next
  end
  topic.update!(quick_stats: qs)
  updated << "#{slug} (#{qs.size})"
end

puts "[quick_stats_backfill batch3] UPDATED #{updated.size}: #{updated.join(', ')}"
puts "[quick_stats_backfill batch3] SKIPPED #{skipped.size}: #{skipped.join(', ')}" if skipped.any?
