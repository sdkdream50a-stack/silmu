# frozen_string_literal: true
#
# AEO Sprint3 quick_stats 백필 — 배치4 (복무·인사·예산·회계·계약 안정조문 10토픽)
# 2026-06-03. quick_stats = [{label,value,note}] 배열(뷰 show.html.erb:190 렌더, category 미사용).
# 값은 운영 DB의 기존 검증 콘텐츠(law/decree/rule_content·FAQ)에서 추출한 **안정 법령값**만 사용
# (연도변동 단가·기관별 상이 기준·품목별 고시값 제외, 조문 고정 율·기한·한도·절차·요건 구조만).
#  근거: 지방회계법 §29·§31·§32·§42~§46·§50~§52 / 회계관계직원책임법 §4 /
#        지방공무원법 §30의4·§56·§65 / 국가공무원법 §32의4·§64·§73 / 공무원임용령 §57 /
#        지방·국가공무원 복무규정(겸직·공가) / 청탁금지법 §10 /
#        공유재산 및 물품 관리법 §5·§11·§13·§19 / 공공감사법 §23의2 /
#        지방계약법 §17·§18·시행령 §64·§67(검사 14일·대가 5일=배치1 검증값 재사용) /
#        중소기업제품 구매촉진 및 판로지원법 §12.
# silmu 지방공무원 우선 원칙: 인사·복무·회계는 지방 법령을 우선/병기.
# 정합성 회피:
#   ① direct-production-confirm 확인증 유효기간(2~3년)=품목별 고시 상이→value는 "품목별 상이"·조문만
#   ② construction-completion 검사/대가 기한은 배치1 completion-payment-checklist의 검증 조문
#      (§17·시행령§64 / §18·시행령§67) 재사용해 일관성 확보
#   ③ secondment·reinstatement 파견·휴직 기간은 조문 고정값만(연장 사유는 note)
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_quick_stats_backfill_2026_06_03_batch4.rb})"'

qs_by_slug = {
  "extra-budgetary-fund" => [
    { "label" => "보관 원칙", "value" => "종류별 구분 후 금고 보관", "note" => "지방회계법 시행령 제51조" },
    { "label" => "현금 직접 취급", "value" => "법정 예외(일직비·여비 등) 외 금지", "note" => "지방회계법 시행령 제52조" },
    { "label" => "금고 검사", "value" => "연 1회 이상 정기 검사", "note" => "지방회계법 시행령 제50조" },
    { "label" => "회계 책임", "value" => "회계관계공무원 임명·분리", "note" => "지방회계법 제44조·제46조" }
  ],
  "concurrent-position" => [
    { "label" => "영리업무 유형", "value" => "경영·임원·직무관련 투자·계속적 이득", "note" => "지방공무원법 제56조·복무규정 제10조" },
    { "label" => "겸직 허가", "value" => "사전에 소속 기관장 허가", "note" => "직무 수행에 지장 없는 경우만" },
    { "label" => "허가 주체", "value" => "임용권자(지방의회 소속은 의장)", "note" => "지방공무원 복무규정 제11조" },
    { "label" => "외부강의", "value" => "사례금 유무 무관 신고", "note" => "청탁금지법 제10조(직무 관련 시)" }
  ],
  "reinstatement" => [
    { "label" => "복귀 신고", "value" => "사유 소멸 후 30일 이내", "note" => "지방공무원법 제65조·국가공무원법 제73조" },
    { "label" => "당연 복직", "value" => "휴직기간 만료 후 30일 내 신고 시", "note" => "별도 임용처분 불요" },
    { "label" => "기한 초과", "value" => "무단결근 간주 → 징계 사유", "note" => "30일 도과 시" },
    { "label" => "육아휴직 복직", "value" => "좌천성 배치 금지", "note" => "지방공무원법 제63조·국가공무원법 제71조" }
  ],
  "secondment" => [
    { "label" => "국내 파견", "value" => "2년 이내(연장 가능)", "note" => "지방공무원법 제30조의4·국가공무원법 제32조의4" },
    { "label" => "국외·민간 파견", "value" => "국외 3년·민간 2년(1회 연장)", "note" => "공무원임용령 제27조의2 이하" },
    { "label" => "민간 파견", "value" => "본인 동의 필요", "note" => "기관 간 파견은 인사명령(동의 불요)" },
    { "label" => "경력 산입", "value" => "승진소요연수·호봉에 전 기간 산입", "note" => "급여는 원소속 기관 지급 원칙" }
  ],
  "public-property-management" => [
    { "label" => "재산 구분", "value" => "행정재산 / 일반재산", "note" => "공유재산 및 물품 관리법 제5조" },
    { "label" => "행정재산 사용허가", "value" => "5년 이내(갱신 가능)", "note" => "공유재산법 제21조" },
    { "label" => "일반재산 대부", "value" => "토지·건물 10년·그 밖 5년 이내", "note" => "공유재산법 제31조" },
    { "label" => "취득·처분", "value" => "공유재산관리계획 → 지방의회 의결", "note" => "공유재산법 제11조(행정재산은 용도폐지 후)" }
  ],
  "official-leave" => [
    { "label" => "공가 사유", "value" => "법정 7개 사유에 한함", "note" => "지방공무원 복무규정(국가 복무규정 제19조)" },
    { "label" => "급여", "value" => "봉급·수당 전액 지급", "note" => "공제 없음" },
    { "label" => "건강검진", "value" => "법령 근거 검진만 인정", "note" => "사립기관 개인 검진은 연가 처리" },
    { "label" => "부여 기간", "value" => "사유별 필요한 기간", "note" => "병역·소환·투표·헌혈·국가행사 등" }
  ],
  "audit-immunity" => [
    { "label" => "면책 요건", "value" => "공익성·적극성·결과발생·고의중과실 부존재(모두 충족)", "note" => "공공감사에 관한 법률 제23조의2" },
    { "label" => "고의·중과실 부존재 추정", "value" => "사적 이해관계 없음 + 중대 절차하자 없음", "note" => "두 조건 동시 충족" },
    { "label" => "신청 시점", "value" => "감사결과 처분요구 이전", "note" => "사전컨설팅 의견대로 처리 시 징계 면제" },
    { "label" => "면책 제외", "value" => "금품수수·무사안일·특혜처리 등", "note" => "법정 제외 사유 해당 시 면책 불가" }
  ],
  "construction-completion" => [
    { "label" => "준공검사 기한", "value" => "검사 요청 후 14일 이내", "note" => "지방계약법 제17조·시행령 제64조(재난 시 7일)" },
    { "label" => "준공금 지급", "value" => "검사 후 청구받은 날부터 5일 이내", "note" => "지방계약법 제18조·시행령 제67조" },
    { "label" => "불합격 시", "value" => "보완·재시공 후 재검사", "note" => "불합격일~재검사 합격일 지체상금 산정" },
    { "label" => "지급 순서", "value" => "검사 합격 → 대가 지급", "note" => "검사 전 지급 시 변상 책임" }
  ],
  "direct-production-confirm" => [
    { "label" => "근거", "value" => "직접생산 확인 의무", "note" => "중소기업제품 구매촉진 및 판로지원법 제12조" },
    { "label" => "확인 주체", "value" => "중소기업중앙회(중기부 위탁)", "note" => "신청 경로 SMPP(smpp.go.kr)" },
    { "label" => "유효기간", "value" => "품목별 고시 기준 상이", "note" => "갱신 필요(품목 고시로 확인)" },
    { "label" => "위반 제재", "value" => "계약 해지 + 부정당업자 제재", "note" => "허위 시 형사처벌 가능" }
  ],
  "expenditure-commitment" => [
    { "label" => "행위 한도", "value" => "세출예산·계속비 범위 내", "note" => "지방회계법 제29조" },
    { "label" => "담당자", "value" => "재무관(위임 공무원)", "note" => "지방회계법 제29조제2항" },
    { "label" => "집행 4단계", "value" => "지출원인행위 → 지출 → 지급명령 → 지급", "note" => "지방회계법 제31조·제32조" },
    { "label" => "선집행 금지", "value" => "사전 지출원인행위 절대 금지", "note" => "위반 시 변상책임(회계관계직원책임법 제4조)" }
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

puts "[quick_stats_backfill batch4] UPDATED #{updated.size}: #{updated.join(', ')}"
puts "[quick_stats_backfill batch4] SKIPPED #{skipped.size}: #{skipped.join(', ')}" if skipped.any?
