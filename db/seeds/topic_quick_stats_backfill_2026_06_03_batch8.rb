# frozen_string_literal: true

#
# AEO Sprint3 quick_stats 백필 — 배치8 (즉시 착수군 4토픽)
# 2026-06-03. quick_stats = [{label,value,note}] 배열(뷰 show.html.erb:190 렌더).
# 값은 korean-law MCP로 직접 재검증한 **조문 고정 안정 법령값/구조**만 사용.
#  검증 근거(korean-law MCP, 2026-06-03):
#    지방재정법(법, mst281909) §38·§41·§47
#    지방계약법(법, mst253973) §2·§13 / 시행령(mst286149) §2·§42의2(삭제)
#    공무원 여비 규정(대통령령, mst282471) §1·§2
#    지방자치단체 입찰 및 계약집행기준(행안부 예규, 행정규칙ID 29508, 2026-05-28 공포)
# silmu 지방공무원 우선 원칙: 지방재정법·지방계약법 우선 인용.
#
# 🛡️ 정합성 회피(운영DB 분석관 초안의 조문 오류·드리프트 전수 정정):
#   ① qualification-failure: 분석관 "시행령 §42의2(적격심사 2억·95점)"는 **§42의2 삭제 확정**
#      (korean-law 실측: "제42조의2 삭제"). 95점·2억·배점은 예규(입찰 및 계약집행기준) 값으로
#      변동 가능 → 하드코딩 회피. 근거는 지방계약법 §13②1(이행능력·적정성 심사)·§13③(위임)만.
#   ② foreign-travel: 본문 "공무국외여행에 관한 규정 제3조"는 **부존재 대통령령**(이전 세션 정정 이력).
#      국외 일비·숙박비·식비는 별표(연도 개정 드리프트) → 단가 하드코딩 회피. 여비 종류(§2)·근거·
#      허가체계(기관 훈령·조례, 단일 대통령령 아님)만.
#   ③ instructor-allowance: 강사 단가 전부 연도 변동 → 구조/근거 조문(§47 목적외 금지·§38③ 통보)만.
#   ④ budget-compilation-guideline: 단가·인상률 연도 변동 → 과목구분(§41)·편성기준 위임(§38)만.
#                                   시달 월(9~12월)은 업무편람 관행 → value 하드코딩 회피.
#
# ⛔ 본 배치 제외(안정 법령 앵커 부재 — 배치7 제외 결정 재확인):
#   - goods-vs-service-contract: 지방계약법 §2=적용범위, 시행령 §2=추정가격/예정가격/고시금액/
#     공사이행보증서 정의뿐(물품·용역 정의 없음). 70% 룰·용역 6유형은 예규(드리프트) → 제외.
#   - e-bidding-error-faq: "시행령 §16의2" 미존재 확정(이전 tools audit). 나라장터 시스템 운영
#     정보(고객센터·PDF 용량 등)는 법령 수치 아님 → 제외.
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_quick_stats_backfill_2026_06_03_batch8.rb})"'

qs_by_slug = {
  "budget-compilation-guideline" => [
    { "label" => "편성기준 근거", "value" => "회계연도별 예산편성기준은 행정안전부령으로 규정", "note" => "지방재정법 제38조제2항" },
    { "label" => "세입 과목 구분", "value" => "장(章)·관(款)·항(項)", "note" => "지방재정법 제41조제1항" },
    { "label" => "세출 과목 구분", "value" => "분야·부문·정책사업 / 단위사업·세부사업·목", "note" => "지방재정법 제41조제2항" },
    { "label" => "업무편람·지출기준", "value" => "행안부장관이 재정운용 업무편람 보급·건전 재정지출 기준 통보", "note" => "지방재정법 제38조제1항·제3항" }
  ],
  "instructor-allowance" => [
    { "label" => "지급 원칙", "value" => "세출예산에서 정한 목적·비목 범위 내 지급(목적 외 사용 금지)", "note" => "지방재정법 제47조" },
    { "label" => "집행기준 근거", "value" => "행안부장관이 건전 재정지출 기준(세출예산 집행기준)을 통보", "note" => "지방재정법 제38조제3항" },
    { "label" => "집행기준 이원화", "value" => "일반 지자체=행안부 예규 / 시·도교육청=교육부 예규", "note" => "교육비특별회계 세출예산 집행기준" },
    { "label" => "단가 특성", "value" => "강사 등급·시간별 차등, 단가는 연도별 개정으로 변동", "note" => "수강인원 등 지급 증빙 구비 필수" }
  ],
  "qualification-failure" => [
    { "label" => "적격심사 근거", "value" => "최저가 입찰자의 계약이행능력·입찰금액 적정성 심사", "note" => "지방계약법 제13조제2항제1호" },
    { "label" => "세부기준 위임", "value" => "적용대상·낙찰자 선정기준은 대통령령·행안부 예규로 규정", "note" => "지방계약법 제13조제3항·지방자치단체 입찰 및 계약집행기준" },
    { "label" => "심사 구성", "value" => "이행실적·경영상태·기술능력·신인도 등 종합평점", "note" => "입찰 및 계약집행기준(예규) — 점수기준 변동 가능" },
    { "label" => "탈락·재공고", "value" => "종합평점 미달 시 차순위 적격심사, 적격자 없으면 재입찰", "note" => "최저가 순으로 적격 여부 심사" }
  ],
  "foreign-travel" => [
    { "label" => "여비 근거", "value" => "공무원 여비 규정(대통령령) — 지방공무원은 조례로 별도 규정", "note" => "공무원 여비 규정 제1조" },
    { "label" => "여비 종류", "value" => "운임·일비·숙박비·식비·이전비·가족여비·준비금", "note" => "공무원 여비 규정 제2조" },
    { "label" => "국외 단가", "value" => "직급·지역등급별 별표 기준(연도 개정으로 변동)", "note" => "단가 하드코딩 부적합 — 최신 별표 확인" },
    { "label" => "허가·근거 형식", "value" => "소속 기관장 사전 승인 + 귀국 후 결과보고서 제출", "note" => "단일 대통령령 아님 — 기관 훈령·조례 적용" }
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

puts "[quick_stats_backfill batch8] UPDATED #{updated.size}: #{updated.join(', ')}"
puts "[quick_stats_backfill batch8] SKIPPED #{skipped.size}: #{skipped.join(', ')}" if skipped.any?
