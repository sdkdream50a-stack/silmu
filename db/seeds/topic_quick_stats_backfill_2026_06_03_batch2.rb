# frozen_string_literal: true

#
# AEO Sprint3 quick_stats 백필 — 배치2 (복무·인사·예산 안정조문 8토픽)
# 2026-06-03. quick_stats = [{label,value,note}] 배열. 값은 이번 세션 FAQ 백필에서 검증한
# 안정 법령값만 사용(연도변동 단가 제외, 조문 고정 율·기한·한도만).
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_quick_stats_backfill_2026_06_03_batch2.rb})"'

qs_by_slug = {
  "holiday-bonus" => [
    { "label" => "지급액", "value" => "봉급월액의 60%", "note" => "공무원수당 등에 관한 규정 제18조의3" },
    { "label" => "지급 횟수", "value" => "연 2회(설날·추석)", "note" => "각 1회" },
    { "label" => "기준일", "value" => "명절 전월 말일 재직자", "note" => "전월 말일 봉급 기준" },
    { "label" => "휴직 중", "value" => "원칙 미지급", "note" => "출산전후·유산·사산휴가는 예외 지급" }
  ],
  "annual-leave" => [
    { "label" => "연가일수", "value" => "재직기간별 11~21일", "note" => "국가공무원 복무규정 제15조" },
    { "label" => "연가 저축", "value" => "연 10일 이내 이월", "note" => "복무규정 제15조의2" },
    { "label" => "연가보상비", "value" => "미사용 최대 20일분", "note" => "봉급월액÷30 기준" },
    { "label" => "사용 단위", "value" => "반일·시간 단위 가능", "note" => "기관 규정에 따름" }
  ],
  "disciplinary-action" => [
    { "label" => "징계 종류", "value" => "파면·해임·강등·정직·감봉·견책", "note" => "국가공무원법 제79조" },
    { "label" => "징계 시효", "value" => "일반 3년 / 금품·횡령 5년 / 성비위 10년", "note" => "국가공무원법 제83조의2" },
    { "label" => "소청 청구", "value" => "처분 통보 후 30일 이내", "note" => "집행정지 효력 없음" },
    { "label" => "임용 제한", "value" => "파면 5년 / 해임 3년", "note" => "국가공무원법" }
  ],
  "leave-of-absence" => [
    { "label" => "질병휴직", "value" => "1년 이내(최대 2년)", "note" => "국가공무원법 제72조 · 봉급 70%" },
    { "label" => "공무상 질병", "value" => "3년 이내", "note" => "봉급 전액" },
    { "label" => "육아휴직", "value" => "자녀 1명당 3년 이내", "note" => "국가공무원법 제71조" },
    { "label" => "무급 휴직", "value" => "간호·학업·동반·자기개발", "note" => "원칙 봉급 미지급" }
  ],
  "position-suspension" => [
    { "label" => "능력부족(1호)", "value" => "봉급의 80%", "note" => "지방공무원 보수규정 제28조" },
    { "label" => "징계요구·기소·수사(2~4호)", "value" => "봉급의 50%", "note" => "3개월 경과 후 30%" },
    { "label" => "대기명령", "value" => "능력부족 시 3개월", "note" => "교육훈련·연구과제 부여" },
    { "label" => "소청 청구", "value" => "처분 후 30일 이내", "note" => "집행정지 효력 없음" }
  ],
  "overtime-allowance" => [
    { "label" => "시간당 단가", "value" => "봉급기준액 × 1/209 × 150%", "note" => "수당규정 제15조제2항" },
    { "label" => "월 한도", "value" => "1일 4시간 · 월 57시간", "note" => "초과분 무급(예외 제외)" },
    { "label" => "평일 산정", "value" => "-1시간 공제", "note" => "토·공휴일은 공제 없음" },
    { "label" => "부정수령 제재", "value" => "5배 가산 징수", "note" => "2회 이상 적발 시 징계의결 요구" }
  ],
  "budget-settlement" => [
    { "label" => "출납 폐쇄", "value" => "다음 연도 2월 10일", "note" => "지방재정법" },
    { "label" => "결산서 작성", "value" => "출납 폐쇄 후 80일 이내", "note" => "지방자치법 제150조" },
    { "label" => "의회 승인", "value" => "다음 연도 8월 31일까지", "note" => "지방자치법 제150조" },
    { "label" => "결산검사위원", "value" => "지방의회 선임", "note" => "지방회계법 제14조" }
  ],
  "budget-compilation" => [
    { "label" => "예산안 제출", "value" => "시·도 50일 전 / 시·군·구 40일 전", "note" => "지방자치법 제127조" },
    { "label" => "의회 의결", "value" => "시·도 15일 전 / 시·군·구 10일 전", "note" => "회계연도 개시 전" },
    { "label" => "행안부 편성기준", "value" => "매년 5월 31일까지 통보", "note" => "지방재정법 시행령 제37조" },
    { "label" => "의결 전 계약", "value" => "금지(사전 지출원인행위)", "note" => "지방재정법 제36조" }
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

puts "[quick_stats_backfill batch2] UPDATED #{updated.size}: #{updated.join(', ')}"
puts "[quick_stats_backfill batch2] SKIPPED #{skipped.size}: #{skipped.join(', ')}" if skipped.any?
