# P2 R1 / P-1 — `topics.faqs` 저장 형태 정규화
#
# 무엇을 고치나: jsonb 컬럼에 **문자열로 갇힌** FAQ 를 배열로 되돌린다.
#   운영 실측(2026-09-06) — ARRAY_OK 110 · STRING_PARSEABLE 2 · STRING_BROKEN 2
#   STRING_BROKEN 2건(`bid-announcement` 4 · `bidding` 5)은 `Topic#faq_list` 의 rescue 가
#   `[]` 를 반환해 **FAQ 9건이 화면·"바로 답"에서 사라져 있었다.**
#
# 무엇을 안 고치나:
#   · FAQ **내용**은 한 글자도 바꾸지 않는다. 표현 형식만 배열로 옮긴다.
#   · 모양이 어긋난 payload 는 손대지 않고 목록만 출력한다 — 억지 복구는 창작이다.
#   · `updated_at` 을 건드리지 않는다(`update_column`). 콘텐츠 개정이 아니라 저장 형식 정정이므로
#     편집 이력·freshness 판정을 오염시키면 안 된다.
#
# slug 하드코딩을 하지 않는 이유: dev(18건)와 운영(4건)의 대상이 다르다.
# 구조로 판정해야 양쪽 모두에서 옳다.
#
# 멱등: 두 번째 실행은 대상 0건.

normalized = []
skipped    = []

authored_before  = 0
reachable_before = 0

Topic.find_each do |topic|
  raw = topic.faqs
  authored_before  += FaqPayloadNormalizer.authored_count(raw)
  reachable_before += topic.faq_list.size

  next if raw.is_a?(Array)

  status, value = FaqPayloadNormalizer.call(raw)

  unless FaqPayloadNormalizer::RECOVERABLE.include?(status)
    skipped << { slug: topic.slug, status: status }
    next
  end

  # 불변식: 복원된 모든 question/answer 가 원문 문자열 안에 그대로 있어야 한다.
  # 하나라도 어긋나면 변환이 내용을 바꾼 것이므로 적용하지 않는다.
  unless FaqPayloadNormalizer.preserves_source?(raw, value)
    skipped << { slug: topic.slug, status: :content_drift }
    next
  end

  topic.update_column(:faqs, value)
  normalized << { slug: topic.slug, count: value.size }
end

authored_after  = 0
reachable_after = 0
Topic.find_each do |topic|
  authored_after  += FaqPayloadNormalizer.authored_count(topic.faqs)
  reachable_after += topic.reload.faq_list.size
end

puts "    [faq-normalize] 정규화 #{normalized.size}건 / 건너뜀 #{skipped.size}건"
normalized.each { |n| puts "      + #{n[:slug]} (FAQ #{n[:count]}건)" }
skipped.each    { |s| puts "      ! #{s[:slug]} — #{s[:status]} (손대지 않음)" }
puts "    [faq-normalize] authored #{authored_before} → #{authored_after} (변동 0 이어야 정상)"
puts "    [faq-normalize] reachable #{reachable_before} → #{reachable_after} (증가분 = 되살린 FAQ)"

if authored_before != authored_after
  raise "FAQ 저작 건수가 변했다 (#{authored_before} → #{authored_after}) — 정규화가 내용을 바꿨다"
end
