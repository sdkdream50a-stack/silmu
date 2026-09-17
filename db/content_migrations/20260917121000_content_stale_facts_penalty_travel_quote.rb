# 구기준 사실 정정 — 지체상금률 · 국내 여비 · 1인 견적 한도 (2026-09-17 전수감사 G-10·G-11·G-12)
#
# 운영 읽기 전용 스캔(Topic·Guide·AuditCase 전 컬럼, jsonb 포함)으로 찾은 문자열만 정확 치환한다.
# 각 치환은 **정확히 1회 이상 존재**해야 하고, 하나라도 없으면 전체를 롤백한다(부분 적용 금지).
#
# 근거:
#   · 지체상금률 — 지방계약법 시행규칙 제75조: 공사 0.5/1,000 · 물품(제조·구매) 0.8/1,000 · 용역 1.3/1,000.
#     한도 30% 는 시행령 제90조. 요율은 시행령이 아니라 시행규칙이 정한다.
#   · 국내 여비 — 공무원 여비 규정 별표2(2026.6.30 개정): 일비·식비 1일 각 25,000원(직급 차등 없음),
#     숙박비는 실비, 상한 서울 100,000 · 광역시 80,000 · 그 밖 70,000원.
#   · 1인 견적 — 지방계약법 시행령 제30조제1항제2호: 추정가격 2천만원 이하(청년창업·여성·장애인기업 등 5천만원 이하).
#     «1인 견적 5백만원 이하»는 근거 없음.
# 국외여비(foreign-travel-private-tourism)는 별도 별표 체계라 이번 범위 밖(스캔 오탐).

subs = [
  # ── 지체상금 ─────────────────────────────────────────────
  [ Topic, "penalty-reduction-procedure", :law_content, [
    [ "지체상금의 요율(1일당 1/1000)과 감면 기준은 시행령에서 규정합니다.",
      "지체상금의 요율(1일당 공사 0.5/1,000 · 물품 0.8/1,000 · 용역 1.3/1,000)은 시행규칙 제75조, 한도(30%)와 감면 기준은 시행령 제90조에서 규정합니다." ]
  ] ],
  [ Topic, "penalty-reduction-procedure", :decree_content, [
    [ "📌 1일당 계약금액의 1/1000</strong>",
      "📌 1일당 계약금액 × 지체상금률 (공사 0.5/1,000 · 물품 0.8/1,000 · 용역 1.3/1,000, 시행규칙 제75조)</strong>" ],
    [ "지체상금 = 계약금액 × 지체일수 × 1/1000", "지체상금 = 계약금액 × 지체일수 × 지체상금률" ]
  ] ],
  [ Topic, "penalty-reduction-procedure", :commentary, [
    [ "- 지체상금: 1억 × 10일 × 1/1000 = 100만원", "- 지체상금: 1억 × 10일 × 0.5/1,000(공사) = 50만원" ],
    [ "- 지체상금: 5,000만 × 15일 × 1/1000 = 75만원", "- 지체상금: 5,000만 × 15일 × 0.8/1,000(물품) = 60만원" ],
    [ "  - 지체상금: 100,000,000원 × 10일 × 1/1000 = 1,000,000원", "  - 지체상금: 100,000,000원 × 10일 × 0.5/1,000(공사) = 500,000원" ]
  ] ],
  [ Guide, "suui-contract-complete-5", :rich_media, [
    [ "계약서에 지체상금률 명시 필요 (통상 1/1000 per day).",
      "계약서에 지체상금률 명시 필요 (1일당 공사 0.5/1,000 · 물품 0.8/1,000 · 용역 1.3/1,000, 지방계약법 시행규칙 제75조)." ]
  ] ],
  [ Guide, "suui-contract-complete-6", :sections, [
    [ "지체상금: 납기 초과 시 적용 요율 (예: 1/1000/일)", "지체상금: 납기 초과 시 적용 요율 (예: 물품 0.8/1,000/일, 시행규칙 제75조)" ]
  ] ],
  [ Guide, "suui-contract-complete-6", :rich_media, [
    [ "예: 1/1000 per day = 100만원 계약에서 하루 지체 시 1,000원 공제.", "예: 물품 0.8/1,000 per day = 100만원 계약에서 하루 지체 시 800원 공제." ],
    [ "요율 명시 (예: 1/1000/일)", "요율 명시 (예: 물품 0.8/1,000/일)" ]
  ] ],
  [ Guide, "suui-contract-complete-7", :rich_media, [
    [ "예: 1천만원 × 1/1000 × 10일 = 10만원", "예: 물품 1천만원 × 0.8/1,000 × 10일 = 8만원" ]
  ] ],
  # ── 국내 여비 ────────────────────────────────────────────
  [ Topic, "travel-expense", :summary, [
    [ "일비 2만원, 식비 2.5만원, 숙박비 정액 7만원(기타 도시)이 기준입니다.",
      "일비·식비 1일 각 2만5천원, 숙박비는 실비(상한 서울 10만·광역시 8만·그 밖 7만원)가 기준입니다(공무원 여비 규정 별표2, 2026.6.30 개정)." ]
  ] ],
  [ Topic, "travel-expense-settlement", :decree_content, [
    [ "| 일비 | 20,000원 | 20,000원 |\n| 식비 | 25,000원 | 20,000원 |",
      "| 일비 | 25,000원 | 25,000원 |\n| 식비 | 25,000원 | 25,000원 |" ]
  ] ],
  [ Topic, "domestic-travel-allowance", :law_content, [
    [ "| 일비 (1일) | 20,000원 | 20,000원 |\n| 식비 (1일) | 25,000원 | 20,000원 |\n| 숙박비 상한 | 70,000원 | 60,000원 |",
      "| 일비 (1일) | 25,000원 | 25,000원 |\n| 식비 (1일) | 25,000원 | 25,000원 |\n| 숙박비 상한 | 서울 100,000 · 광역시 80,000 · 그 밖 70,000원 | 서울 100,000 · 광역시 80,000 · 그 밖 70,000원 |" ]
  ] ],
  [ Topic, "domestic-travel-allowance", :decree_content, [
    [ "- 일비: 25,000원 × 2일 = 40,000원\n- 숙박비: 실제 지출액 (최대 60,000원)\n- 식비: 20,000원 × 2일 = 40,000원\n- **합계: 교통비 + 130,000원 + 숙박비**",
      "- 일비: 25,000원 × 2일 = 50,000원\n- 숙박비: 실제 지출액 (상한 서울 100,000 · 광역시 80,000 · 그 밖 70,000원)\n- 식비: 25,000원 × 2일 = 50,000원\n- **합계: 교통비 + 100,000원 + 숙박비**" ]
  ] ],
  [ Guide, "travel-expense-complete-2", :sections, [
    [ "5급 이상: 일비 약 2만원, 식비 약 2만5천원 (1일 기준)", "모든 직급: 일비 25,000원, 식비 25,000원 (1일 기준, 직급 차등 없음)" ],
    [ "6~7급: 일비 약 2만원, 식비 약 2만원 (1일 기준)", "숙박비: 실비 — 상한 서울 100,000원 · 광역시 80,000원 · 그 밖 70,000원" ],
    [ "8~9급: 일비 약 2만원, 식비 약 2만원 (1일 기준)", "근거: 공무원 여비 규정 별표2(2026.6.30 개정)" ]
  ] ],
  # ── 1인 견적 한도 ────────────────────────────────────────
  [ AuditCase, "single-quote-exceeds-limit", :detail, [
    [ "이 경우에도 2개 이상 업체로부터 견적을 징수하는 2인 이상 견적과 달리, 1인 견적은 5백만원 이하에서만 적용됩니다.",
      "추정가격 2천만원 이하에서는 1인 견적이 허용되고(시행령 제30조제1항제2호, 청년창업·여성·장애인기업 등은 5천만원 이하), 그 초과는 원칙적으로 2인 이상 견적 또는 경쟁입찰 대상입니다." ],
    [ "| 5백만원 이하 | 1인 견적 수의계약 | 단독 견적 가능 |\n| 5백만원 초과 ~ 2천만원 이하 | 2인 이상 견적 수의계약 | 복수 견적 의무 |",
      "| 2천만원 이하 | 수의계약 (1인 견적 가능) | 시행령 제25조제1항제5호나목·제30조제1항제2호 |" ]
  ] ],
  [ AuditCase, "single-quote-exceeds-limit", :lesson, [
    [ "그중 **1인 견적(단독 견적)**은 **5백만원 이하**에서만 허용됩니다. 5백만원 초과~2천만원 이하에서는 반드시 **2인 이상**의 견적을 받아야 합니다.",
      "이 범위에서는 **1인 견적(단독 견적)**도 허용됩니다(시행령 제30조제1항제2호). 청년창업·여성·장애인기업 등은 5천만원 이하까지 1인 견적이 가능합니다." ]
  ] ]
]

# load 로 실행되므로 전역 메서드·상수를 만들지 않는다.
deep_sub = lambda do |value, from, to|
  case value
  when String then value.gsub(from, to)
  when Array  then value.map { |v| deep_sub.call(v, from, to) }
  when Hash   then value.transform_values { |v| deep_sub.call(v, from, to) }
  else value
  end
end

contains = lambda do |value, needle|
  case value
  when String then value.include?(needle)
  when Array  then value.any? { |v| contains.call(v, needle) }
  when Hash   then value.values.any? { |v| contains.call(v, needle) }
  else false
  end
end

ActiveRecord::Base.transaction do
  applied = 0
  subs.each do |klass, slug, column, pairs|
    record = klass.find_by!(slug: slug)
    value = record.public_send(column)
    pairs.each do |from, to|
      next if contains.call(value, to) && !contains.call(value, from) # 멱등: 이미 정정됨
      raise "STALE_TEXT_NOT_FOUND #{klass.name}/#{slug}/#{column}: #{from[0, 40]}" unless contains.call(value, from)

      value = deep_sub.call(value, from, to)
      applied += 1
    end
    record.update_columns(column => value, updated_at: Time.current)
  end
  puts "  [stale-facts] substitutions applied=#{applied}"
end
