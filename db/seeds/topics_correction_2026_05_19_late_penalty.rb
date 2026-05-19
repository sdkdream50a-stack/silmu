# 2026-05-19 Phase 3.2 후속 patch — find_or_create_by! 함정 우회
# topics.rb / topic_late_penalty.rb는 commit 036491e에서 정정되었으나,
# find_or_create_by!는 기존 레코드의 필드 갱신 안 됨.
# 이 patch는 idempotent gsub 패턴으로 운영 DB의 기존 레코드 update.
#
# 실행: kamal app exec --reuse 'bin/rails runner "load \"db/seeds/topics_correction_2026_05_19_late_penalty.rb\""'

corrections = {
  "late-penalty" => {
    decree_content: {
      "계약금액의 10%** (지방계약법 시행규칙 제75조 단서)" => "계약금액의 30%** (지방계약법 시행령 제90조 제3항)"
    },
    rule_content: {
      "계약금액의 10%를 초과할 수 없음** (지방계약법 시행규칙 제75조 단서)" => "계약금액의 30%를 초과할 수 없음** (지방계약법 시행령 제90조 제3항)",
      "10% 한도 초과 시 → 계약금액의 10%" => "30% 한도 초과 시 → 계약금액의 30%",
      "계약금액의 10% 도달" => "계약금액의 30% 도달"
    },
    _faqs: [
      [ "최고한도는 계약금액의 10%입니다(시행규칙 제75조 단서).", "최고한도는 계약금액의 30%입니다(시행령 제90조 제3항)." ],
      [ "계약금액의 10%가 최고한도입니다(시행규칙 제75조 단서).", "계약금액의 30%가 최고한도입니다(시행령 제90조 제3항)." ]
    ]
  },
  "penalty-reduction-procedure" => {
    commentary: {
      # 운영 DB에는 "까지만 부과" 변형이 있음 — 두 변형 모두 매칭
      "계약금액의 10%입니다(지방계약법 시행규칙 제75조 단서). 예: 1억원 계약이면 최대 1,000만원까지만 부과됩니다." =>
        "계약금액의 30%입니다(지방계약법 시행령 제90조 제3항). 예: 1억원 계약이면 최대 3,000만원까지만 부과됩니다.",
      "계약금액의 10%입니다(지방계약법 시행규칙 제75조 단서). 예: 1억원 계약이면 최대 1,000만원까지 부과됩니다." =>
        "계약금액의 30%입니다(지방계약법 시행령 제90조 제3항). 예: 1억원 계약이면 최대 3,000만원까지 부과됩니다."
    }
  }
}

corrections.each do |slug, fields|
  topic = Topic.find_by(slug: slug)
  unless topic
    puts "⚠️  Topic not found: #{slug}"
    next
  end

  changed = false
  fields.each do |field, gsub_map|
    if field == :_faqs
      next unless topic.faqs.is_a?(Array)
      new_faqs = topic.faqs.map do |faq|
        next faq unless faq.is_a?(Hash)
        faq.transform_values do |v|
          if v.is_a?(String)
            gsub_map.each { |from, to| v = v.gsub(from, to) }
          end
          v
        end
      end
      if new_faqs != topic.faqs
        topic.faqs = new_faqs
        changed = true
      end
    else
      val = topic.send(field)
      next unless val.is_a?(String)
      new_val = val.dup
      gsub_map.each { |from, to| new_val = new_val.gsub(from, to) }
      if new_val != val
        topic.send("#{field}=", new_val)
        changed = true
      end
    end
  end

  if changed
    topic.save!
    puts "✅ #{slug} updated"
  else
    puts "ℹ️  #{slug} already up-to-date (no gsub matches)"
  end
end
