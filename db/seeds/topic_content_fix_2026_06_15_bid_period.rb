# frozen_string_literal: true

#
# 토픽 본문 법령정정 — 입찰공고 시기(시행령 §35) 공고기간 체계 정정
# 2026-06-15. cf. PR #58 (소스 시드 정정과 동일 치환).
#
# 정본(law.go.kr + LBOX 이중검증, 지방계약법 시행령 §35 입찰공고의 시기):
#   ① 일반 7일 / ③ 공사(현장설명 미실시): 10억미만 7·10~50억 15·50억~고시금액 30·고시금액↑ 40일 /
#   ⑤ 규격·기술·협상: 1억미만 10·1~10억 20·10억↑ 40일 / ④ 긴급 5일.
#
# 결함: bidding·bid-announcement가 공고기간을 "고시금액 2단계(7/40)"로 단순화하고
#   "지방계약법엔 국가계약법의 10억/50억 구간이 없다"고 명시 → §35③에 실재하는 구간을 부정(YMYL 오류).
#   고시 주체도 조달청장/기획재정부로 오기(지방계약은 행정안전부장관). 긴급입찰 조항 §35⑤→§35④ 오인용.
#
# 적용 이유: 두 토픽 시드가 find_or_create_by! 라 기존(프로덕션) 행은 블록 스킵 → 소스 시드(PR #58)만으로는
#   미반영. 본 파일이 update! 문자열 치환으로 기존 행에 정본을 반영(decree_content 변경 시 law_verified_at
#   자동 갱신 + after_commit IndexNow 재색인 핑). destroy 금지(subtopics dependent:destroy / guides·audit_cases nullify).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_15_bid_period.rb})"'
# 재실행 안전(idempotent): 이미 정정된 행은 old 미존재 → MISS 출력(no-op).

# ── 치환 정의 ───────────────────────────────────────────────

bidding_decree_table_old = <<~OLD.rstrip
  ### 제35조 (입찰공고)

  | 추정가격 | 공고기간 |
  |---------|---------|
  | 고시금액 미만 | **7일** 이상 |
  | 고시금액 이상 (국제입찰) | **40일** 이상 |
  | 긴급입찰 | **5일**까지 단축 가능 (사유 명시) |
OLD

bidding_decree_table_new = <<~NEW.rstrip
  ### 제35조 (입찰공고의 시기)

  | 구분 | 추정가격 | 공고기간 |
  |------|---------|---------|
  | 일반 입찰(원칙) | — | **7일** |
  | 공사입찰(현장설명 미실시) | 10억원 미만 | **7일** |
  | 〃 | 10억원 이상 50억원 미만 | **15일** |
  | 〃 | 50억원 이상 고시금액 미만 | **30일** |
  | 〃 | 고시금액 이상 | **40일** |
  | 규격·기술·협상 입찰 | 1억원 미만 / 1억~10억 / 10억 이상 | **10 / 20 / 40일** |
  | 긴급·재공고 등 | — | **5일**까지 단축 (사유 명시) |
NEW

bidding_decree_note_old =
  "> ※ 고시금액은 조달청장이 매년 고시 (WTO 정부조달협정 적용 기준). " \
  "국가계약법 시행령은 10억/50억/국제입찰의 3단계 구분이나, 지방계약법 시행령은 고시금액 기준 2단계 구분입니다."

bidding_decree_note_new =
  "> ※ 고시금액은 행정안전부장관이 매년 고시(국제입찰 대상 기준 금액). " \
  "공사입찰은 추정가격에 따라 7·15·30·40일로 공고기간이 단계화되며(시행령 §35③), " \
  "현장설명을 하는 경우는 현장설명일 기준으로 별도 기산합니다(§35②)."

bidding_faq_old =
  "지방계약법 시행령 제35조에 따라, 고시금액 미만은 7일 이상, 고시금액 이상(국제입찰)은 40일 이상 공고해야 합니다. " \
  "긴급한 경우 5일까지 단축할 수 있습니다. 참고로 국가계약법은 10억 미만 7일/10억 이상 15일/국제입찰 40일의 3단계 구분입니다."

bidding_faq_new =
  "지방계약법 시행령 제35조에 따라 일반 입찰은 7일 이상이 원칙입니다. " \
  "현장설명을 하지 않는 공사입찰은 추정가격에 따라 10억원 미만 7일·10억~50억원 15일·50억~고시금액 30일·고시금액 이상 40일로 단계화됩니다. " \
  "긴급한 경우 5일까지 단축할 수 있습니다(법정 사유 필요)."

ba_decree_table_old = <<~OLD.rstrip
  ### 공고기간

  | 추정가격 | 최소 공고기간 |
  |---------|------------|
  | 고시금액 미만 | **7일** 이상 |
  | 고시금액 이상 (국제입찰) | **40일** 이상 |
  | 긴급입찰 | **5일** (사유 명시) |

  ※ 고시금액: 국제입찰 대상 금액으로 기획재정부 고시에 따름 (공사: 약 229억원, 물품/용역: 약 2.6억SDR 상당)
  ※ 기간 산정: 공고일·입찰일 제외, 역일(曆日) 기준
OLD

ba_decree_table_new = <<~NEW.rstrip
  ### 공고기간

  입찰서 제출 마감일의 전날부터 기산하여 다음 기간 전에 공고해야 합니다.

  | 구분 | 추정가격 | 최소 공고기간 |
  |------|---------|------------|
  | 일반 입찰(원칙) | — | **7일** |
  | 공사입찰(현장설명 미실시) | 10억원 미만 | **7일** |
  | 〃 | 10억원 이상 50억원 미만 | **15일** |
  | 〃 | 50억원 이상 고시금액 미만 | **30일** |
  | 〃 | 고시금액 이상 | **40일** |
  | 규격·기술·협상 입찰 | 1억원 미만 / 1억~10억 / 10억 이상 | **10 / 20 / 40일** |
  | 긴급·재공고 등 | — | **5일**까지 단축 (사유 명시) |

  ※ 공사입찰에 현장설명을 하는 경우는 현장설명일 전날부터 기산(원칙 7일, 사전심사 대상 공사는 30일) — 시행령 §35②
  ※ 고시금액: 국제입찰 대상 기준 금액으로 행정안전부장관이 고시
  ※ 기간 산정: 공고일·입찰일 제외, 역일(曆日) 기준
NEW

# bid-announcement practical_tips 빠른확인표 — 2행을 4행으로 (긴급 행은 무수정)
ba_quicktable_old =
  %(          <tr><td class="py-1">고시금액 미만</td><td>7일+</td><td>5일+</td></tr>\n) +
  %(          <tr><td class="py-1">고시금액 이상 (국제입찰)</td><td>40일+</td><td>20일+</td></tr>)
ba_quicktable_new =
  %(          <tr><td class="py-1">10억원 미만</td><td>7일+</td><td>5일+</td></tr>\n) +
  %(          <tr><td class="py-1">10억~50억원</td><td>15일+</td><td>8일+</td></tr>\n) +
  %(          <tr><td class="py-1">50억~고시금액</td><td>30일+</td><td>15일+</td></tr>\n) +
  %(          <tr><td class="py-1">고시금액 이상</td><td>40일+</td><td>20일+</td></tr>)

ba_confuse_old =
  %(<li><strong>국제입찰 기준 혼동:</strong> 고시금액 미만(7일)과 이상(40일, 국제입찰)의 공고기간이 크게 다름</li>)
ba_confuse_new =
  %(<li><strong>공고기간 단계 혼동:</strong> 공사입찰은 추정가격 구간별로 7·15·30·40일로 달라짐 — 10억·50억·고시금액이 분기점</li>)

ba_faq_old =
  "지방계약법 시행령 제35조에 따라 고시금액 미만은 7일 이상, 고시금액 이상(국제입찰)은 40일 이상입니다. " \
  "긴급한 경우 5일까지 단축 가능하나 법정 사유가 있어야 합니다."
ba_faq_new =
  "지방계약법 시행령 제35조에 따라 일반 입찰은 7일 이상이 원칙입니다. " \
  "현장설명을 하지 않는 공사입찰은 추정가격에 따라 10억원 미만 7일·10억~50억원 15일·50억~고시금액 30일·고시금액 이상 40일로 달라집니다. " \
  "긴급한 경우 5일까지 단축 가능하나 법정 사유가 있어야 합니다."

fixes = [
  [ "bidding", "decree_content", [
    [ bidding_decree_table_old, bidding_decree_table_new ],
    [ bidding_decree_note_old, bidding_decree_note_new ]
  ] ],
  [ "bidding", "faqs", [
    [ bidding_faq_old, bidding_faq_new ]
  ] ],
  [ "bid-announcement", "decree_content", [
    [ ba_decree_table_old, ba_decree_table_new ],
    [ "### 긴급입찰 (제35조 제5항)", "### 긴급입찰 (제35조 제4항)" ]
  ] ],
  [ "bid-announcement", "practical_tips", [
    [ ba_quicktable_old, ba_quicktable_new ],
    [ ba_confuse_old, ba_confuse_new ]
  ] ],
  [ "bid-announcement", "faqs", [
    [ ba_faq_old, ba_faq_new ]
  ] ]
]

# ── 적용 ───────────────────────────────────────────────

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  content = topic.public_send(field).to_s
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix bid_period] #{results.join(' | ')}"

# ── 잔존 검증 (정정 전 패턴이 0건이어야 CLEAN) ───────────────

puts "--- 잔존 검증 ---"
checks = {
  "bidding" => {
    decree_content: [ "고시금액 기준 2단계 구분", "| 고시금액 미만 | **7일** 이상 |", "조달청장이 매년 고시" ],
    faqs: [ "10억 이상 15일/국제입찰 40일의 3단계" ]
  },
  "bid-announcement" => {
    decree_content: [ "| 고시금액 미만 | **7일** 이상 |", "기획재정부 고시", "긴급입찰 (제35조 제5항)" ],
    practical_tips: [ %(<td class="py-1">고시금액 미만</td>), "국제입찰 기준 혼동" ],
    faqs: [ "고시금액 미만은 7일 이상, 고시금액 이상(국제입찰)은 40일 이상입니다" ]
  }
}
residual = 0
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pats|
    pats.each do |pat|
      n = t.public_send(f).to_s.scan(pat).size
      residual += n
      puts "  #{slug}.#{f} '#{pat[0..28]}…' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
    end
  end
end
puts residual.zero? ? "✅ 전체 CLEAN — 정정 반영 완료" : "⚠️ RESIDUAL #{residual}건 — old 문자열 불일치 확인 필요"
