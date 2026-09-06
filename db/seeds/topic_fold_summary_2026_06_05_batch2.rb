# frozen_string_literal: true

#
# 토픽 fold intent 감사 2차 (2026-06-05) — answer-first 요약 재작성
#
# 1차(6건)에 이어, 운영DB 조회수 상위 40토픽을 전수 스캔해 "안내합니다"형
# 범위서술/정의 요약 + quick_stats 보유(=검증값으로 업그레이드 가능) 10건 추가.
# quick_stats 0인 토픽(goods-selection-committee·bid-qualification)은 근거 없어 제외.
#
# 원칙: 새 법령 주장 0. 각 토픽 기보유 quick_stats 검증값만 첫 문장으로(answer-first).
#       update!로 updated_at 갱신 → topic_md 캐시 자동 무효. 카드 truncate(60) 안전.

FOLD_SUMMARIES = {
  "contract-execution" =>
    "계약서에는 목적·금액·이행기간·계약보증금·위험부담·지연배상금을 필수 기재하고 전자문서로 작성하는 것이 원칙입니다(계약금액 5천만원 이하 등은 계약서 생략 가능). 계약 변경·해제·해지 요건까지 정리했습니다.",
  "private-contract-limit" =>
    "수의계약이 가능한 추정가격 한도는 종합공사 4억원·전문공사 2억원·물품·용역 2천만원 이하이며, 청년창업기업은 5천만원·소기업·소상공인·여성·장애인·사회적기업 등은 1억원까지 가능합니다.",
  "private-contract-amount" =>
    "추정가격 2천만원 이하(특례기업 5천만원)는 1인 견적, 한도 이하 구간은 2인 이상 견적으로 최저가를 선정합니다. 200만원 이하는 견적서도 생략할 수 있습니다.",
  "payment" =>
    "계약대금은 청구일부터 5일 이내 지급해야 하며, 선금은 계약금액의 70% 이내, 하도급대금 직접지급은 원수급인 수령 후 15일 이내입니다. 지연이자·선금 정산 실무까지 정리했습니다.",
  "dual-quote" =>
    "추정가격 2천만~1억원 구간은 2인 이상 견적을 받아 최저가로 수의계약합니다. 안내공고는 3일 이상, 2천만원 초과 시 나라장터(G2B) 전자견적이 필수입니다.",
  "contract-guarantee-deposit" =>
    "계약보증금은 계약금액의 10% 이상, 입찰보증금은 입찰금액의 5% 이상, 하자보증금은 공종별 2~5%입니다. 납부 기준·금액 산정·면제 요건을 정리했습니다.",
  "bid-announcement" =>
    "입찰공고는 원칙 7일 이상이며, 공사입찰(현장설명 미실시)은 추정가격 10억 미만 7일·10~50억 15일·50억~고시금액 30일·고시금액 이상 40일입니다. 재공고·긴급은 5일. 필수 기재사항·재공고 절차까지 정리했습니다.",
  "design-change" =>
    "공사량 증감 시 계약금액을 조정하며, 신규비목 단가는 설계변경 당시 단가에 낙찰률을 곱해 산정(협의 불성립 시 산정단가의 50%)합니다. 단체장 승인은 예정가격 86% 미만 낙찰에 증액 10% 이상일 때 필요합니다.",
  "small-amount-contract" =>
    "추정가격 종합공사 4억원·전문공사 2억원(기타공사 1.6억원)·물품·용역 2천만원 이하에서 가능한 소액 수의계약입니다. 물품·용역은 청년창업기업 5천만원·소기업·소상공인 등 1억원까지 확대됩니다.",
  "emergency-contract" =>
    "천재지변·감염병·재난복구 등 입찰할 여유가 없는 긴급한 사유가 있을 때 1인 견적으로 체결하는 수의계약입니다. 계약 후 내용 공개 의무가 있습니다."
}.freeze

puts "== 토픽 fold 요약 재작성 2차 (2026-06-05) =="
updated = 0
FOLD_SUMMARIES.each do |slug, new_summary|
  topic = Topic.find_by(slug: slug)
  unless topic
    puts "  ⚠️  미발견: #{slug} (건너뜀)"
    next
  end
  old = topic.summary.to_s
  if old == new_summary
    puts "  =  변경없음: #{slug}"
    next
  end
  topic.update!(summary: new_summary)
  updated += 1
  puts "  ✅ #{slug} (#{topic.name})"
  puts "       이전: #{old.truncate(48)}"
  puts "       이후: #{new_summary.truncate(48)}"
end
puts "== 완료: #{updated}건 변경 / 총 #{FOLD_SUMMARIES.size}건 =="
