# 자가용 출장 연료비 근거 정정 (2026-09-17 전수감사 G-20 NEEDS_REVIEW 해소)
#
# 원문: 공무원 여비 규정 [별표 2] 국내 여비 지급표 <개정 2026. 6. 30.> 비고 제4호
#   «자가용 승용차를 이용하여 공무로 여행하는 경우의 운임은 철도운임 또는 버스운임으로 한다. 다만, 공무의 형편상 부득이한 사유로
#    자가용 승용차를 이용한 경우에는 연료비 및 통행료 등을 지급할 수 있고 구체적인 지급 기준은 인사혁신처장이 기획예산처장관과 협의하여 정한다.»
#   일비·식비 1일 각 25,000원(직급 구분 없음). 제18조는 «근무지 내 국내 출장 시의 여비»다.
# «기획재정부(재정경제부)가 분기마다 유류비 기준단가를 고시» 조문은 확인되지 않았다.

subs = [
  [ Topic, "vehicle-travel-allowance", :regulation_content, [
    [ "#### 자가용 이용 여비 지급 기준 (공무원 여비규정 제18조)", "#### 자가용 이용 여비 지급 기준 (공무원 여비 규정 별표 2 비고 제4호)" ],
    [ "| 연료비 | 실제 주행거리 × 유가 기준 단가 (재정경제부 고시) |", "| 운임 | 원칙은 철도운임 또는 버스운임. 부득이한 사유로 자가용을 이용한 경우 연료비·통행료 등 지급 가능 |" ],
    [ "| 일비 | 해당 직급 일비 기준 100% |", "| 일비 | 1일 25,000원 (별표 2, 직급 구분 없음) |" ],
    [ "| 식비 | 해당 직급 식비 기준 100% |", "| 식비 | 1일 25,000원 (별표 2, 직급 구분 없음) |" ],
    [ "연료비 지급 단위는 km당 일정 금액으로 산정하며, 기획재정부가 분기마다 유류비 기준단가를 고시합니다.",
      "연료비·통행료의 구체적인 지급 기준은 인사혁신처장이 기획예산처장관과 협의하여 정합니다(공무원 여비 규정 별표 2 비고 제4호)." ]
  ] ],
  [ Guide, "travel-expense-complete-10", :sections, [
    [ "기획재정부 여비 관련 유권해석", "인사혁신처 여비 관련 질의회신" ]
  ] ]
]

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
changed = 0

ActiveRecord::Base.transaction do
  subs.each do |klass, slug, column, pairs|
    record = klass.find_by!(slug: slug)
    value = record.public_send(column)
    pairs.each do |from, to|
      next if contains.call(value, to) && !contains.call(value, from)
      raise "STALE_TEXT_NOT_FOUND #{slug}/#{column}: #{from[0, 40]}" unless contains.call(value, from)

      value = deep_sub.call(value, from, to)
      changed += 1
    end
    record.update_columns(column => value, updated_at: Time.current) unless dry_run
  end
  puts "  [travel-fuel] #{dry_run ? 'DRY_RUN ' : ''}changes=#{changed}"
  raise ActiveRecord::Rollback if dry_run
end
