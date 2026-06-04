# frozen_string_literal: true
#
# AEO Sprint3 quick_stats 백필 — 배치1 (계약·예산 안정조문 8토픽)
# 2026-06-03. quick_stats = [{label, value, note}] 배열(뷰 show.html.erb:190 렌더, category 미사용).
# 값은 이번 세션 korean-law MCP로 검증한 **안정적 법령값**만 사용(드리프트 위험 율 제외).
#  검증근거: 지방계약법 §15(보증금10%)·§17(검사)·§18(대가)·§22(물가/설계변경 조정)·
#           시행령§90③(지체상금30%한도)·시행규칙§75(지연배상금률)·시행령§64(검사14일)·§67(대가5일)·§74(설계변경/86%/10%),
#           지방재정법 §11·§41의3(지방채/채무비율25·40%/일시차입)·§43(예비비1%).
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_quick_stats_backfill_2026_06_03_batch1.rb})"'

qs_by_slug = {
  "late-penalty" => [
    { "label" => "지체상금 상한", "value" => "계약금액의 30%", "note" => "지방계약법 시행령 제90조 제3항" },
    { "label" => "지체일수 기산", "value" => "납기일 다음 날부터", "note" => "실제 납품·준공일까지" },
    { "label" => "감면 사유", "value" => "발주기관 귀책·천재지변·불가항력", "note" => "계약상대자 과실은 감면 불가" },
    { "label" => "한도 초과 시", "value" => "발주기관 계약 해지 가능", "note" => "지방계약법 시행령" }
  ],
  "penalty-reduction-procedure" => [
    { "label" => "지체상금 상한", "value" => "계약금액의 30%", "note" => "지방계약법 시행령 제90조 제3항" },
    { "label" => "감면 가능 사유", "value" => "발주기관 귀책·천재지변·불가항력", "note" => "해당 기간 지체일수 공제" },
    { "label" => "감면 불가", "value" => "계약상대자 과실(인력·자재 조달 실패)", "note" => "감면 대상 아님" },
    { "label" => "신청 방법", "value" => "지연 사유·일수 + 증빙 서면 신청", "note" => "구두 설명만으로는 불가" }
  ],
  "contract-amount-adjustment" => [
    { "label" => "물가변동 요건", "value" => "계약 후 90일 경과 + 지수 3% 이상 변동", "note" => "지방계약법 제22조" },
    { "label" => "조정 근거", "value" => "물가변동·설계변경·계약내용 변경", "note" => "지방계약법 제22조·시행령 제74조" },
    { "label" => "신청 시기", "value" => "계약 이행 중", "note" => "이행 완료 후 소급 조정 불가" },
    { "label" => "재조정 간격", "value" => "직전 조정 기준일부터 90일 경과", "note" => "지방계약법 시행령" }
  ],
  "contract-guarantee-exemption" => [
    { "label" => "계약보증금 기본", "value" => "계약금액의 100분의 10 이상", "note" => "지방계약법 제15조" },
    { "label" => "면제 가능 대상", "value" => "국가·지자체·공공기관 / 소액 계약", "note" => "지방계약법 제15조 단서·시행령" },
    { "label" => "면제 성격", "value" => "임의적 면제(발주기관 판단)", "note" => "필수 면제 아님" },
    { "label" => "분할 회피 금지", "value" => "동일 목적 분할 시 합산 판단", "note" => "분할발주 금지 원칙" }
  ],
  "additional-contract-limit" => [
    { "label" => "조정 근거", "value" => "물가변동·설계변경 등", "note" => "지방계약법 제22조·시행령 제74조" },
    { "label" => "증감 단가", "value" => "계약단가 적용(원칙)", "note" => "신규비목은 설계변경 당시 단가×낙찰률" },
    { "label" => "단체장 승인", "value" => "저가낙찰(예정가 86%미만) 증액분 원계약금액 10% 이상", "note" => "지방계약법 시행령 제74조제3항" },
    { "label" => "한도 회피", "value" => "동일 목적물 분리 발주 금지", "note" => "분할발주 금지" }
  ],
  "completion-payment-checklist" => [
    { "label" => "검사 기한", "value" => "이행 완료 통지 후 14일 이내", "note" => "지방계약법 제17조·시행령 제64조(재난시 7일)" },
    { "label" => "대가 지급 기한", "value" => "검사 후 청구받은 날부터 5일 이내", "note" => "지방계약법 제18조·시행령 제67조(공휴일·토요일 제외)" },
    { "label" => "지급 순서", "value" => "검사 합격 → 하자보수보증금 → 대가", "note" => "검사 전 지급 시 변상 책임" },
    { "label" => "지연 시", "value" => "지연일수 이자 가산", "note" => "지방계약법 시행령 제68조" }
  ],
  "contingency-fund" => [
    { "label" => "일반예비비 한도", "value" => "일반회계 예산총액의 1% 이내", "note" => "지방재정법 제43조" },
    { "label" => "목적예비비", "value" => "재해·재난 대비 별도 편성", "note" => "지정 목적 외 사용 금지" },
    { "label" => "사용 요건", "value" => "예측불가·긴급·예산부족·목적적합 모두 충족", "note" => "지방재정법 시행령 제65조" },
    { "label" => "사후 절차", "value" => "다음 회계연도 의회 사용명세서 승인", "note" => "지방재정법 제43조" }
  ],
  "public-debt-management" => [
    { "label" => "발행 절차", "value" => "지방의회 의결 필수", "note" => "지방재정법 제11조" },
    { "label" => "행안부 승인", "value" => "채무비율 25% 초과 시", "note" => "재정건전화계획 수립 의무" },
    { "label" => "특별관리", "value" => "채무비율 40% 초과 시", "note" => "행정안전부 특별관리 대상" },
    { "label" => "일시차입", "value" => "예산총액 1/10 이내·30일 이내", "note" => "지방재정법 제41조의3(의회 의결 불요)" }
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

puts "[quick_stats_backfill batch1] UPDATED #{updated.size}: #{updated.join(', ')}"
puts "[quick_stats_backfill batch1] SKIPPED #{skipped.size}: #{skipped.join(', ')}" if skipped.any?
