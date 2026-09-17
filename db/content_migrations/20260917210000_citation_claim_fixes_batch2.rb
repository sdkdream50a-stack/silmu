# 조문 인용 문장의 원문 불일치 정정 2차 (2026-09-17 전수감사 G-37)
#
# tools/g37_scan2.py 로 «조문 인용 + 숫자» 문장을 조문 원문 숫자와 대조해 뽑은 뒤, 원문을 직접 읽어 확정한 건만 고친다.
# 원문(law.go.kr): 지방회계법 제24조(일시차입금 — 한도액 미리 지방의회 의결·해당 연도 수입으로 상환) · 제7조(출납은 회계연도 끝나는 날 폐쇄,
#   출납사무 다음 회계연도 2월 10일까지 완결) · 지방자치법 제150조(출납 폐쇄 후 80일 이내 결산서·다음 해 지방의회 승인) · 제145조(추경 의결, 제142조③④ 준용) ·
#   지방계약법 제30조의2①2호(지연배상금 계약금액 100분의 10 이상 + 이행 가능성 없음 명백 → 해제·해지 가능) · 제12조③(낙찰자 미체결 시 입찰보증금 귀속) ·
#   지방계약법 시행령 제90조③(지연배상금 한도 100분의 30) · 제49조(계약서 서식 위임 — 체결 기한 없음) · 국가공무원 복무규정 제17조⑤(연 6일 초과 병가는 연가에서 공제,
#   진단서 첨부분 제외) · 공무원수당 등에 관한 규정 제18조의3(명절휴가비 — 지급기준일 = 설날·추석날 현재 재직, 월봉급액 60퍼센트,
#   보수지급일 또는 지급기준일 전후 15일 이내 지급; «전월 말일 기준» 없음) · 공무원임용령 제41조②(파견 2년 이내, 총 5년) · 공무원 여비 규정 제5조(여행일수의 계산 — 청구 기한 없음) · 지방재정법 제17조(기부 또는 보조의 제한).
# 없음을 확인한 것: 지방재정법 제41조의3 · 지방재정법 제45조 «회기 개시 3일 전».

subs = [
  [ Topic, "public-debt-management", :interpretation_content, [
    [ "다만, 긴급한 경우 단기 자금 융통(일시차입)은 지방재정법 제41조의3에 따라 지방의회 의결 없이 가능하며, 이 경우 당해 연도 예산 총액의 1/10 이내에서 30일 이내 기간 동안 차입할 수 있습니다.",
      "일시차입금도 지방회계법 제24조에 따라 회계연도마다 회계별로 그 한도액에 대해 미리 지방의회의 의결을 얻어야 하며, 해당 회계연도의 수입으로 상환해야 합니다." ]
  ] ],
  [ Topic, "public-debt-management", :faqs, [
    [ "지방채 발행은 지방의회 의결이 필수이지만, 긴급한 단기 자금 융통인 일시차입은 의회 의결 없이 가능합니다. 일시차입은 당해 연도 예산 총액의 10분의 1 이내에서 30일 이내 기간으로 한정됩니다(지방재정법 제41조의3).",
      "지방채 발행은 지방의회 의결이 필수입니다(지방재정법 제11조). 일시차입금도 회계연도마다 회계별 한도액에 대해 미리 지방의회의 의결을 얻어야 하고, 해당 회계연도의 수입으로 상환해야 합니다(지방회계법 제24조)." ]
  ] ],
  [ Topic, "public-debt-management", :quick_stats, [
    [ "지방재정법 제41조의3(의회 의결 불요)", "지방회계법 제24조(한도액 미리 의회 의결)" ],
    [ "예산총액 1/10 이내·30일 이내", "해당 회계연도 수입으로 상환" ]
  ] ],
  [ Topic, "penalty-reduction-procedure", :interpretation_content, [
    [ "**[회신]** 지체상금이 계약금액의 30%를 초과하는 경우 발주기관은 계약을 해지할 수 있습니다(지방계약법 제30조의2). 계약 해지는 권리이므로 발주기관이 재량으로 결정하며, 계속 이행이 가능하고 필요한 경우 30% 이상에서도 계약을 유지할 수 있습니다. 다만, 지체상금은 30%(지방계약법 시행령 제90조 제3항)를 초과하여 부과할 수 없습니다.",
      "**[회신]** 지방계약법 제30조의2 제1항 제2호에 따라 지연배상금이 계약금액의 100분의 10 이상이고 계약상대자의 귀책사유로 계약을 이행할 가능성이 없음이 명백하다고 인정되면 계약을 해제 또는 해지할 수 있습니다(재량). 지연배상금은 계약금액의 100분의 30을 한도로 합니다(지방계약법 시행령 제90조 제3항)." ]
  ] ],
  [ Topic, "budget-settlement", :faqs, [
    [ "회계연도 종료 후 출납 폐쇄는 2월 10일까지이며, 단체장은 출납 폐쇄 후 80일 이내(약 5월 초)에 결산서를 작성하고, 지방의회는 다음 연도 8월 31일까지 결산을 승인해야 합니다(지방회계법 제14조).",
      "출납은 회계연도가 끝나는 날 폐쇄하고 출납사무는 다음 회계연도 2월 10일까지 마쳐야 합니다(지방회계법 제7조). 단체장은 출납 폐쇄 후 80일 이내에 결산서와 증명서류를 작성해 검사위원의 검사의견서를 첨부하고, 다음 해 지방의회의 승인을 받아야 합니다(지방자치법 제150조)." ]
  ] ],
  [ Topic, "budget-settlement", :practical_tips, [
    [ "2월 10일(출납 폐쇄)까지", "2월 10일(출납사무 완결기한)까지" ]
  ] ],
  [ Topic, "budget-settlement", :regulation_content, [
    [ "3. **감사위원회 검사**: 지방회계법 제14조에 따라 감사위원회 결산 검사", "3. **검사위원 검사**: 지방회계법 제14조·지방자치법 제150조에 따라 지방의회가 선임한 검사위원의 결산 검사" ]
  ] ],
  [ Topic, "annual-leave", :interpretation_content, [
    [ "「국가공무원 복무규정」 제16조에 따라 병가를 6일 이상 사용한 경우 그 초과 일수에 비례하여 연가 일수가 공제됩니다.",
      "「국가공무원 복무규정」 제17조 제5항에 따라 연간 6일을 초과하는 병가 일수는 연가 일수에서 공제됩니다(의사의 진단서를 첨부한 병가 일수는 공제하지 않음)." ]
  ] ],
  [ Topic, "sick-leave", :interpretation_content, [
    [ "**[회신]** 「국가공무원 복무규정」 제16조에 따라 연간 병가 사용 일수가 6일을 초과하는 경우, 초과 일수의 1/2에 해당하는 일수를 연가 일수에서 공제합니다. 병가 20일 사용 시 초과분 14일의 1/2인 7일이 연가에서 공제되며, 공제된 연가는 연가보상비 지급 대상에서도 제외됩니다.",
      "**[회신]** 「국가공무원 복무규정」 제17조 제5항에 따라 연간 6일을 초과하는 병가 일수는 연가 일수에서 공제합니다. 다만, 의사의 진단서를 첨부한 병가 일수는 공제하지 않습니다. 예를 들어 진단서 없이 병가를 20일 사용했다면 초과분 14일이 연가 일수에서 공제됩니다." ]
  ] ],
  [ Topic, "travel-expense", :practical_tips, [
    [ "   - 여비는 출장 완료 후 **30일 이내** 청구해야 함 (공무원 여비 규정 제5조)", "   - 여비 청구 기한은 공무원 여비 규정에 따로 없으므로 소속 기관 여비 지급 지침을 확인" ]
  ] ],
  [ Topic, "supplementary-budget", :interpretation_content, [
    [ "**[회신]** 지방재정법 제45조 제2항에 따라 추경 예산은 회기 개시 3일 전까지 제출하는 것이 원칙이나, 긴급한 사유 발생 시 회기 중에도 제출 가능합니다. 이 경우 지방의회는 제출일로부터 5일 이내에 예산결산특별위원회 심사를 거쳐 의결할 수 있으며, 자치단체 조례로 별도 기한을 정할 수 있습니다.",
      "**[회신]** 추가경정예산안은 지방자치법 제145조에 따라 편성해 지방의회의 의결을 받아야 하며, 같은 조 제2항이 제142조 제3항·제4항을 준용합니다. 지방재정법 제45조에는 «회기 개시 3일 전» 같은 제출 기한이 없으므로, 구체적 일정은 해당 지방의회 회의 규칙·조례를 확인하세요." ]
  ] ],
  [ Topic, "secondment", :regulation_content, [
    [ "총 파견 기간이 5년을 초과하지 않는 범위에서 연장할 수 있다(「국가공무원법」 제32조의4).", "총 파견 기간이 5년을 초과하지 않는 범위에서 연장할 수 있다(「국가공무원법」 제32조의4, 「공무원임용령」 제41조 제2항)." ]
  ] ],
  [ Topic, "bidding", :commentary, [
    [ "낙찰자 결정 후 <strong>10일 이내</strong> 계약을 체결해야 하며(국가계약법 시행령 제49조), ", "계약 체결 기한은 입찰공고와 「지방자치단체 입찰 및 계약 집행기준」에서 정한 기한을 따르며, " ]
  ] ],
  [ Topic, "e-bidding-error-faq", :interpretation_content, [
    [ "낙찰자가 정당한 사유 없이 낙찰통지를 받은 날부터 10일 이내에 계약을 체결하지 않으면 낙찰을 취소하고 입찰보증금을 귀속 처리합니다(지방계약법 시행령 제49조).",
      "낙찰자가 계약을 체결하지 않으면 입찰보증금을 해당 지방자치단체에 귀속시켜야 합니다(지방계약법 제12조 제3항). 계약 체결 기한은 입찰공고와 「지방자치단체 입찰 및 계약 집행기준」에서 정한 기한을 확인하세요." ]
  ] ],
  [ Topic, "holiday-bonus", :faqs, [
    [ "명절이 속한 달의 전월 말일을 기준으로 봉급을 받는 공무원에게 지급합니다. 예를 들어 설날이 2월이면 1월 31일이 기준일이 되어 1월 급여 지급 시 함께 지급됩니다.",
      "설날 및 추석날(지급기준일) 현재 재직 중인 공무원에게 지급하며, 보수지급일 또는 지급기준일 전후 15일 이내에 기관장이 정하는 날에 지급합니다(공무원수당 등에 관한 규정 제18조의3)." ],
    [ "기준일(전월 말일) 전에 퇴직하면 지급 대상에서 제외되고, 기준일 이후 퇴직 예정이면 전액 지급됩니다. 기준일 현재 휴직 중이면 원칙적으로 제외되나, 출산전후휴가·유산·사산휴가 중인 경우는 예외적으로 지급됩니다.",
      "지급기준일(설날·추석날) 현재 재직 중이어야 지급 대상입니다. 휴직자 지급 여부는 규정 본문에 없으므로 인사혁신처 「공무원보수 등의 업무지침」을 확인하세요." ]
  ] ],
  [ Topic, "holiday-bonus", :practical_tips, [
    [ "✅ 기준일(명절 전월 말일) 현재 재직자 명단 확정", "✅ 지급기준일(설날·추석날) 현재 재직자 명단 확정" ]
  ] ],
  [ Topic, "holiday-bonus", :qa_content, [
    [ "A. 정확히는 설날이 속한 달의 전월 말일 기준으로 재직 중인 경우 지급 대상입니다. 명절 당일이 아닌 전월 말일이 기준입니다.",
      "A. 설날 및 추석날(지급기준일) 현재 재직 중이면 지급 대상입니다(공무원수당 등에 관한 규정 제18조의3 제1항)." ]
  ] ],
  [ Topic, "holiday-bonus", :quick_stats, [
    [ "전월 말일 봉급 기준", "제18조의3 제1항" ],
    [ "명절 전월 말일 재직자", "설날·추석날 현재 재직자" ]
  ] ],
  [ Guide, "construction-contract-complete-5", :sections, [
    [ "지방계약법 시행령 제91조", "지방회계법 제35조" ],
    [ "선금 지급 요건 및 한도 — 계약 금액의 70% 이내, 보증서 제출 조건", "선금급과 개산급 — 선금 지급 한도·요건은 「지방자치단체 입찰 및 계약 집행기준」 확인" ]
  ] ],
  [ Guide, "local-subsidy-complete-1", :sections, [
    [ "지방재정법 제17조 (보조금의 교부)", "지방재정법 제17조 (기부 또는 보조의 제한)" ]
  ] ]
]

# quick_stats 는 같은 note 문자열이 여러 항목에 있어 label 로 골라 고친다.
settlement_stats = lambda do |stats|
  stats.map do |item|
    item = item.dup
    case item["label"]
    when "출납 폐쇄"
      item.merge!("label" => "출납사무 완결", "note" => "지방회계법 제7조")
    when "결산서 작성"
      item["note"] = "지방자치법 제150조"
    when "의회 승인"
      item.merge!("note" => "지방자치법 제150조", "value" => "다음 해 지방의회 승인")
    end
    item
  end
end

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

dry_run = ENV["DRY_RUN"] == "1"
applied = 0

ActiveRecord::Base.transaction do
  subs.each do |klass, slug, column, pairs|
    record = klass.find_by!(slug: slug)
    value = record.public_send(column)
    pairs.each do |from, to|
      next if contains.call(value, to) && !contains.call(value, from)
      raise "STALE_TEXT_NOT_FOUND #{klass.name}/#{slug}/#{column}: #{from[0, 40]}" unless contains.call(value, from)

      value = deep_sub.call(value, from, to)
      applied += 1
    end
    record.update_columns(column => value, updated_at: Time.current) unless dry_run
  end

  topic = Topic.find_by!(slug: "budget-settlement")
  fixed = settlement_stats.call(Array(topic.quick_stats))
  if fixed != topic.quick_stats
    raise "SETTLEMENT_STATS_SHAPE_CHANGED" unless Array(topic.quick_stats).any? { |i| i["label"] == "의회 승인" && i["value"].to_s.include?("8월 31일") }

    topic.update_columns(quick_stats: fixed, updated_at: Time.current) unless dry_run
    applied += 1
  end

  puts "  [g37-batch2] #{dry_run ? 'DRY_RUN ' : ''}substitutions=#{applied}"
  raise ActiveRecord::Rollback if dry_run
end
