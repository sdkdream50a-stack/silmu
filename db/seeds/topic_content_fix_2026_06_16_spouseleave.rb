# frozen_string_literal: true
#
# 2026-06-16 special-leave 배우자 출산휴가 현행화 (외과적, 멱등).
# 2025.2.11 국가·지방공무원 복무규정 개정: 배우자 출산휴가 10→20일, 사용기한 출생일로부터 90→120일.
#   (다태아 25일/150일은 본 토픽에 미수록 — 신규 콘텐츠 추가 않음. 분할 횟수는 본문에 수치 미기재.)
# 근거: 대한민국 정책브리핑(korea.kr/news/policyNewsView newsId=148939204), 법제처 보도자료.
#
# 안전성(이 토픽 한정, 운영DB 전수 스캔으로 확인):
#  - "10일"은 배우자 출산 맥락에만 출현(여성 출산 90/120일·유산 5~90일은 "10일" 없음) → 전역 치환 안전.
#  - "출생일로부터 90일"·"소멸하므로 90일"은 배우자 전용 표현 → 여성 "출산 전후 90일"·유산 "5~90일" 불침범.
#  - jsonb quick_stats/faqs는 label/question 가드로 배우자 항목만 수정(경조사 등 보존).

t = Topic.find_by(slug: "special-leave")
abort "❌ special-leave NOT_FOUND" if t.nil?

STR_FIELDS = %w[
  law_content decree_content rule_content regulation_content interpretation_content
  commentary summary qa_content practical_tips
].freeze

# 순서 무관(120일은 10일/90일 패턴 미포함) — 멱등.
STR_SUBS = [
  ["출생일로부터 90일", "출생일로부터 120일"],
  ["소멸하므로 90일",   "소멸하므로 120일"],
  ["10일",              "20일"],
].freeze

changes = {}

STR_FIELDS.each do |f|
  next unless t.respond_to?(f)
  v = t.public_send(f)
  next unless v.is_a?(String)
  nv = v.dup
  STR_SUBS.each { |a, b| nv = nv.gsub(a, b) }
  changes[f] = nv if nv != v
end

# quick_stats: 배우자 출산 항목만
qs = t.quick_stats
if qs.is_a?(Array)
  qs2 = qs.map do |h|
    h = h.dup
    if h["label"].to_s.include?("배우자 출산")
      h["value"] = h["value"].to_s.gsub("10일", "20일")
      h["note"]  = h["note"].to_s.gsub("90일", "120일")
    end
    h
  end
  changes["quick_stats"] = qs2 if qs2 != qs
end

# faqs: 배우자 출산 답변만
fq = t.faqs
if fq.is_a?(Array)
  fq2 = fq.map do |h|
    h = h.dup
    if h["question"].to_s.include?("배우자 출산휴가") || h["answer"].to_s.include?("배우자 출산 시")
      a = h["answer"].to_s
      a = a.gsub("출생일로부터 90일", "출생일로부터 120일").gsub("10일", "20일")
      h["answer"] = a
    end
    h
  end
  changes["faqs"] = fq2 if fq2 != fq
end

if changes.empty?
  puts "special-leave: CLEAN (변경 없음 — 이미 현행화됨)"
else
  changes.each_key { |k| puts "  CHANGED: #{k}" }
  t.update_columns(changes)
  puts "special-leave: FIXED #{changes.keys.size} 필드"
end

# 잔존 검증(배우자 맥락 stale = 0이어야 함; 여성/유산 90일은 정상 잔존)
t.reload
str_10 = STR_FIELDS.count { |f| t.respond_to?(f) && (v = t.public_send(f)).is_a?(String) && v.include?("10일") }
str_b90 = STR_FIELDS.count { |f| t.respond_to?(f) && (v = t.public_send(f)).is_a?(String) && (v.include?("출생일로부터 90일") || v.include?("소멸하므로 90일")) }
qs_bad = (t.quick_stats || []).count { |h| h["label"].to_s.include?("배우자 출산") && (h["value"].to_s.include?("10일") || h["note"].to_s.include?("90일")) }
fq_bad = (t.faqs || []).count { |h| (h["question"].to_s.include?("배우자 출산휴가") || h["answer"].to_s.include?("배우자 출산 시")) && (h["answer"].to_s.include?("10일") || h["answer"].to_s.include?("출생일로부터 90일")) }
puts "→ 배우자 잔존 stale: str10일=#{str_10} str90일=#{str_b90} quick_stats=#{qs_bad} faqs=#{fq_bad} (전부 0이어야 함)"
