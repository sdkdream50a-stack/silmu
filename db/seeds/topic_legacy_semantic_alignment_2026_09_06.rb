# frozen_string_literal: true

#
# R2 ↔ 레거시 콘텐츠 의미 정합 — 운영 DB 정정
# 2026-09-06. cf. topic_source_quality_fix_2026_09_06.rb (동일 패턴).
#
# 배경: R2 판단 엔진(시행령 §7제2호 / §25①5호 / §30①2호 / §77)과 레거시 본문이
#   **같은 질문에 반대 결론**을 내고 있었다. 틀린 쪽은 전부 레거시 문구였다.
#   엔진 semantics 는 한 줄도 바꾸지 않았다.
#
# 정본 (law.go.kr 실측 2026-09-06 · docs/silmu-p2/r2-align/_data/sources_verified.json):
#   지방계약법 시행령 [시행 2026. 6. 3.] [대통령령 제36338호] MST 286149 · 현행
#     §77   "공사의 분할계약 금지" — 표제·본문 모두 공사. ①단서 1~3호가 분할발주를 허용한다.
#     §7제2호  물품·용역의 분할 조달은 **금지가 아니라 추정가격 합산**(직전/직후 12개월 또는 해당 회계연도)
#     §25①5호  나목 일반 2천만 / 다목 청년창업기업 5천만 / 라목 소기업·**소상공인** 1억 /
#              마목 학술연구·원가계산·건설기술 등 1억 / 바목 여성·장애인·사회적기업·
#              사회적협동조합·자활기업·마을기업 1억
#              → 부칙 전문 대조 결과 **유효기간 조항 없음**. "2026.6.30 만료 후 3천만원 회귀"는 부존재
#                (그날 종료된 것은 보증금·절차 한시특례 = 행안부 고시 제2025-72호. 별개다)
#     §30①2호  1인 견적 2천만, 단 가목(청년창업·여성·장애인)·나목(사회적기업·사회적협동조합·
#              자활기업·마을기업)은 5천만 → **§25 의 특례와 대상도 금액도 다르다**
#   행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 [시행 2026.7.1] 예규 제372호
#     제1장 제1절 5.라 — "용역·물품 계약에 대하여도 단일 사업을 **부당하게** 분할하거나 시기적으로
#     나누어 체결하지 않도록 해야 한다. 다만, 도서 등 간행물 구매 시 … 불가피한 사유가 있는
#     경우에는 분할하여 구매할 수 있다."
#
# 운영 실측 (READ-ONLY probe 2026-09-06 · _data/prod_divergence.json · revision ce62d2e):
#   Topic 22 dual-quote / 23 private-contract-limit / 24 private-contract-amount /
#   25 small-amount-contract 에 총 11건. (probe 의 D 2건 중 24번은 §30 문맥이라 정본 — 건드리지 않는다)
#
# ⛔ 건드리지 않는 것:
#   · §30(1인 견적)의 "특례기업 5천만원" — 정본이다. private-contract-amount / single-quote 는 무수정
#   · 실제로 2026.6.30 종료된 보증금·절차 한시특례 서술 — 정본이다
#   · R2 판단 엔진·규칙집·임계값 — 변경 0
#
# 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_legacy_semantic_alignment_2026_09_06.rb})"'
# 멱등: 이미 정정된 경우 old 미존재 → MISS(no-op).
#

# 실측: fold_summary 컬럼은 없다. summary 가 fold 요약을 담는다.
TEXT_FIELDS = %i[
  name law_content decree_content rule_content regulation_content
  practical_tips interpretation_content qa_content verification_source
].freeze

# ── 1. 전 토픽 공통 문자열 정정 ────────────────────────────────
# E — §25①5호라목이 명시한 "소상공인"이 특례 열거에서 빠져 있었다.
#     소상공인 담당자에게는 "1억 특례 대상이 아니다"로 읽힌다.
GLOBAL_SUBS = [
  [ "소기업·여성·장애인", "소기업·소상공인·여성·장애인" ],
  # E — 대상을 밝히지 않은 "특례 1억". 청년창업기업(5천만·다목)까지 1억으로 읽힌다.
  [ "2천만원 (특례 1억)", "2천만원 (청년창업 5천만·소기업 등 1억)" ]
].freeze

# ── 2. C — 분할 절대금지 단정 → 부당한 분할 금지 + 허용 경로 ──
# 운영 DB 의 들여쓰기는 heredoc squiggly 로 제거돼 시드 파일과 다르다(실측).
# 그래서 마크업 블록이 아니라 **문장 단위**로 치환한다 — 들여쓰기에 의존하지 않는다.
SPLIT_SUBS = [
  [ "분할계약 절대 금지!", "부당한 분할계약 금지" ],
  [ "1건의 계약을 2개 이상으로 분할하면 <strong>감사 1순위 지적 대상</strong>입니다.",
    "수의계약 한도나 경쟁입찰을 회피하려고 단일 사업을 나누면 <strong>감사 1순위 지적 대상</strong>입니다. " \
    "다만 <strong>나눴다는 사실만으로 위법이 되지는 않습니다</strong> — 공사는 시행령 제77조제1항 각 호" \
    "(법령상 분리발주·공구별 분할·공종 분리)의 사유가, 물품·용역은 행안부 예규" \
    "(집행기준 제1장 제1절 5.라 단서, 도서 등 불가피한 사유)가 분할을 허용합니다." ]
].freeze

# ── 3. E — 1억 특례 열거에 청년창업 계층이 없던 2곳 ───────────
# GLOBAL_SUBS 가 먼저 돌아 "소기업·소상공인·" 형태가 된 뒤에 매칭된다(순서 의존).
TIER_SUBS = [
  [ "물품·용역: <strong>2천만원 초과 ~ 수의계약 한도</strong> (소기업·소상공인·여성·장애인·사회적기업 등 1억원)",
    "물품·용역: <strong>2천만원 초과 ~ 수의계약 한도</strong> (청년창업 5천만원, 소기업·소상공인·여성·장애인·사회적기업 등 1억원)" ],
  [ "특례: 소기업·소상공인·여성·장애인·사회적기업 등 1억",
    "특례: 청년창업 5천만 · 소기업·소상공인·여성·장애인·사회적기업 등 1억" ]
].freeze

# ── 4. D — 운영 전용 콘텐츠(시드 원천 없음)의 §25 한도 표 ────────
# small-amount-contract#decree_content 는 시드 파일에 대응 원천이 없다(실측).
# 같은 문자열이 §30 문맥에도 있으므로 **슬러그·필드로 범위를 좁혀** 치환한다.
SLUG_FIELD_SUBS = {
  [ "small-amount-contract", "decree_content" ] => [
    [ "(특례기업 5천만원)</span>", "(청년창업 5천만원·소기업 등 1억원)</span>" ]
  ]
}.freeze

changed = Hash.new(0)
missed  = []

apply = lambda do |rec, field, subs|
  v = rec.public_send(field)
  next_v = v.dup
  subs.each { |old, new| next_v = next_v.gsub(old, new) if next_v.include?(old) }
  return false if next_v == v
  rec.public_send("#{field}=", next_v)
  true
end

Topic.find_each do |t|
  dirty = false
  TEXT_FIELDS.each do |f|
    next unless t.respond_to?(f)
    v = t.public_send(f)
    next unless v.is_a?(String) && v.present?
    subs = GLOBAL_SUBS + TIER_SUBS + SPLIT_SUBS + SLUG_FIELD_SUBS.fetch([ t.slug, f.to_s ], [])
    if apply.call(t, f, subs)
      dirty = true
      changed["#{t.slug}##{f}"] += 1
    end
  end

  # D — §25(수의계약 한도) 문맥의 quick_stats 만. §30(견적) 토픽은 정본이므로 제외한다.
  if %w[private-contract-limit small-amount-contract].include?(t.slug) &&
     t.respond_to?(:quick_stats) && t.quick_stats.present?
    qs = t.quick_stats.is_a?(String) ? JSON.parse(t.quick_stats) : t.quick_stats
    hit = false
    qs = qs.map do |row|
      r = row.dup
      if r["note"].to_s.match?(/특례기업\s*5(?:,?000|천)만원/)
        r["note"] = r["note"].include?(",") ? "청년창업 5,000만원·소기업 등 1억원" : "청년창업 5천만원·소기업 등 1억원"
        hit = true
      end
      r
    end
    if hit
      t.quick_stats = t.quick_stats.is_a?(String) ? qs.to_json : qs
      dirty = true
      changed["#{t.slug}#quick_stats"] += 1
    end
  end

  # D — 요약문의 §25 특례 5천만 단정
  # 실측: fold_summary 컬럼은 없다. fold 요약은 summary 에 들어 있다.
  if t.respond_to?(:summary) && t.summary.present?
    fs = t.summary
    nfs = fs
      .gsub("물품·용역 2천만원(특례기업 5천만원) 이하입니다.",
            "물품·용역 2천만원 이하이며, 청년창업기업은 5천만원·소기업·소상공인·여성·장애인·사회적기업 등은 1억원까지 가능합니다.")
      .gsub("물품·용역 2천만원(특례기업 5천만원) 이하에서 가능한 소액 수의계약입니다.",
            "물품·용역 2천만원 이하에서 가능한 소액 수의계약입니다. 물품·용역은 청년창업기업 5천만원·소기업·소상공인 등 1억원까지 확대됩니다.")
    if nfs != fs
      t.summary = nfs
      dirty = true
      changed["#{t.slug}#summary"] += 1
    end
  end

  t.save! if dirty
end

if defined?(AuditCase)
  AuditCase.find_each do |a|
    dirty = false
    %i[title issue content legal_basis].each do |f|
      next unless a.respond_to?(f)
      v = a.public_send(f)
      next unless v.is_a?(String) && v.present?
      dirty = true if apply.call(a, f, GLOBAL_SUBS)
    end
    if dirty
      a.save!
      changed["AuditCase##{a.id}"] += 1
    end
  end
end

missed << "C(절대금지 문구) 미발견 — 이미 정정됐거나 표기가 다르다" if changed.keys.none? { |k| k.end_with?("#practical_tips") }

puts "정정 필드: #{changed.size}"
changed.sort.each { |k, v| puts "  ✓ #{k} (#{v})" }
missed.each { |m| puts "  · MISS #{m}" }
puts "완료 — R2 엔진·규칙집·임계값 변경 0"
