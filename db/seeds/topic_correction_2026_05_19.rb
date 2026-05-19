# 2026-05-19 batch #2 — 지방계약법 시행령 §42 부정확 인용 운영 patch
# topic_bid_announcement / topic_restricted_bidding 두 토픽 시드 모두
# find_or_create_by! 또는 find_or_initialize_by 블록만 사용 (idempotent 아님)
# → 운영 DB 적용용 별도 patch 시드 필요
# 정정 사유:
#   - 시행령 §42(낙찰자 결정)를 "경쟁입찰의 성립/2인 이상" 근거로 잘못 인용
#   - 정확: 행안부 예규 「지방자치단체 입찰 및 계약 집행기준」 + 시행령 §19(재입찰)

corrections = [
  {
    slug: "bid-announcement",
    field: :law_content,
    from: "- **시행령 제42조 (경쟁입찰의 성립):** 입찰자가 2인 이상인 경우에 입찰이 성립",
    to: "- **행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 + 시행령 제19조 (재입찰 및 재공고입찰):** 입찰자가 2인 이상인 경우에 입찰이 성립 (1인 입찰 시 유찰 → 재공고)"
  },
  {
    slug: "restricted-bidding",
    field: :law_content,
    from: "- 지방계약법 시행령 제42조에 따라 입찰자가 **2인 이상**이어야 입찰이 성립합니다.",
    to: "- 행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 및 지방계약법 시행령 제19조(재입찰 및 재공고입찰)에 따라 입찰자가 **2인 이상**이어야 입찰이 성립합니다."
  }
]

# restricted-bidding 의 q_and_a (별도 JSON 필드)
qa_corrections = [
  {
    slug: "restricted-bidding",
    field: :q_and_a,
    from: "지방계약법 시행령 제42조에 따라 입찰자가 2인 이상이어야 입찰이 성립합니다",
    to: "행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 및 지방계약법 시행령 제19조(재입찰 및 재공고입찰)에 따라 입찰자가 2인 이상이어야 입찰이 성립합니다"
  }
]

# bid-deposit 토픽 DB 콘텐츠 정정 (시드 파일이 아닌 운영 DB에 직접 입력된 콘텐츠)
# 발견: 라이브 검증에서 §41(수입입찰 낙찰)·§78(장기계속계약) 부정확 인용 발견
bid_deposit_corrections = [
  {
    slug: "bid-deposit",
    field: :law_content,
    from: "입찰보증금은 지방계약법 시행령 제41조에 따라",
    to: "입찰보증금은 지방계약법 시행령 제37조(입찰보증금)에 따라"
  },
  {
    slug: "bid-deposit",
    field: :law_content,
    from: "입찰보증금을 국고에 귀속시킵니다 (지방계약법 시행령 제78조)",
    to: "입찰보증금을 국고에 귀속시킵니다 (지방계약법 시행령 제38조 — 입찰보증금의 세입조치)"
  },
  {
    slug: "bid-deposit",
    field: :law_content,
    from: "추정가격의 5% 이상",
    to: "입찰금액의 5% 이상"
  }
]

(corrections + qa_corrections + bid_deposit_corrections).each do |c|
  t = Topic.find_by(slug: c[:slug])
  if t.nil?
    puts "  [skipped] #{c[:slug]} — 미존재"
    next
  end
  current = t.send(c[:field])
  next if current.nil?
  new_value = current.gsub(c[:from], c[:to])
  if new_value == current
    puts "  [unchanged] #{c[:slug]} (#{c[:field]}) — 패턴 매칭 0건"
  else
    t.send("#{c[:field]}=", new_value)
    t.save!
    puts "  [updated] #{c[:slug]} (#{c[:field]}) — gsub 적용"
  end
end

puts "✅ 2026-05-19 batch #2 토픽 정정 완료 (#{corrections.size + qa_corrections.size}건 시도)"
