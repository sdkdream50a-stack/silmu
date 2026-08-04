# 2026-08-04 지체상금(지연배상금) 요율·상한 정정
#
# 배경: 토픽 seed는 find_or_create_by! 라서 블록 본문을 고쳐도 **기존 운영 레코드는 갱신되지 않는다**.
# 따라서 잘못된 값이 이미 들어간 운영 DB를 고치려면 이 gsub 스크립트가 필요하다(batch9~19 관례).
#
# 정정 내용
#   1) 공사 지체상금률을 국가 1/1,000 로 서술한 부분 → 국가·지방 모두 0.5/1,000 (동일)
#      실제 차이는 물품(국가 0.75 / 지방 0.8)·용역(국가 1.25 / 지방 1.3)에서 난다.
#   2) 지연배상금 최고 한도 10% → 30% (지방계약법 시행령 제90조 제3항)
#
# 근거: 국가계약법 시행규칙 제75조 / 지방계약법 시행규칙 제75조·시행령 제90조 제3항

REPLACEMENTS = [
  # 기존 운영 레코드의 **주 비교표** 행 (신규 seed에서는 이미 고쳐졌지만 DB에는 구값이 남아 있다)
  [ "| 공사 | **1/1,000** |", "| 공사 | **0.5/1,000** |" ],
  [ "| 물품 제조·구매 | 1.5/1,000 |", "| 물품 제조·구매 | 0.75/1,000 |" ],
  [ "| **공사 지체상금률** | 1/1,000 | 0.5/1,000 |",
    "| **공사 지체상금률** | 0.5/1,000 | 0.5/1,000 (동일) |" ],
  [ "국가 1/1,000 > 지방 0.5/1,000 (지방이 절반)",
    "국가·지방 모두 0.5/1,000 (공사는 동일). 차이는 물품(국가 0.75·지방 0.8)·용역(국가 1.25·지방 1.3)에서 난다" ],
  [ "국가계약법 지체상금률(공사 1/1,000)", "국가계약법 물품 지체상금률(0.75/1,000)" ],
  [ "공사 지체상금률이 국가(1/1,000)와 지방(0.5/1,000)이 다른 이유는?",
    "지체상금률은 국가와 지방이 어떻게 다른가요?" ],
  [ "국가계약법의 요율이 지방계약법보다 2배 높습니다.",
    "공사 요율은 양 법이 같고, 물품·용역에서만 갈립니다." ],
  [ "**최고 한도:** 계약금액의 **10%** (100분의 10, 시행규칙 제75조 단서)",
    "**최고 한도:** 계약금액의 **30%** (100분의 30, 지방계약법 시행령 제90조 제3항)" ],
  [ "계약금액의 10% (시행규칙 제75조 단서)", "계약금액의 30% (시행령 제90조 제3항)" ],
  # 조문 오기: 지방계약법 §16=감독, §17=검사, §18=대가의 지급, §19=대가의 선납
  [ "## 지방계약법 제16조 (검사)", "## 지방계약법 제17조 (검사)" ],
  [ "- **제16조 (검사):**", "- **제17조 (검사):**" ],
  [ "- **제17조 (대가의 지급):**", "- **제18조 (대가의 지급):**" ],
  [ "(지방계약법 제17조, 시행령 제67조)", "(지방계약법 제18조, 시행령 제67조)" ],
  [ "## 지방계약법 제17조 (대가의 지급)", "## 지방계약법 제18조 (대가의 지급)" ],
  # 지연배상금 한도를 계약금액 자체로 서술한 오류
  # "계약금액에 도달" 표현은 문장마다 변형이 있어 정확 일치로는 못 잡는다(도달한 때/도달하면/누적이 …).
  [ /지체상금(이|\s*누적이)?\s*(\*\*)?계약금액에 도달(\*\*)?/,
    "지연배상금이 **법정 한도(계약금액의 30%, 시행령 제90조 제3항)에 도달**" ],
  [ "지체상금이 계약금액을 초과할 수 없습니다", "지연배상금은 계약금액의 30%를 초과할 수 없습니다(시행령 제90조 제3항)" ],
  # 선금 근거를 시행령 위임으로 서술한 오류
  [ "선금률, 지급 절차, 정산 방법 등 세부사항은 시행령에 위임",
    "선금률·지급 절차·정산 방법은 지방회계법 제35조와 행정안전부 예규 「지방자치단체 입찰 및 계약집행기준」, 소속 기관 지침에 따릅니다" ]
].freeze

TEXT_COLUMNS = %w[
  law_content decree_content rule_content regulation_content
  commentary practical_tips qa_content interpretation_content summary
  audit_cases
].freeze

updated = 0

Topic.find_each do |topic|
  changes = {}

  TEXT_COLUMNS.each do |col|
    next unless topic.respond_to?(col)
    original = topic.public_send(col)
    next if original.blank? || !original.is_a?(String)

    fixed = REPLACEMENTS.reduce(original) { |acc, (from, to)| acc.gsub(from, to) }
    changes[col] = fixed if fixed != original
  end

  # jsonb 컬럼(quick_stats·faqs)도 함께 훑는다 — string 컬럼만 보면 누락된다(2026-06-16 교훈).
  %w[quick_stats faqs].each do |col|
    next unless topic.respond_to?(col)
    raw = topic.public_send(col)
    next if raw.blank?

    serialized = raw.to_json
    fixed = REPLACEMENTS.reduce(serialized) { |acc, (from, to)| acc.gsub(from, to) }
    changes[col] = JSON.parse(fixed) if fixed != serialized
  end

  next if changes.empty?

  topic.update_columns(changes)
  updated += 1
  puts "  fixed: #{topic.slug} (#{changes.keys.join(', ')})"
end

puts "지체상금 요율·상한 정정 완료: #{updated}건"
puts "⚠️ update_columns는 updated_at을 갱신하지 않는다 → 적용 후 Rails.cache.clear + CF purge 필요"
