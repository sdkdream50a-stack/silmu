# 정부조직 개편(2026-01-02) 반영 — DB 콘텐츠의 «기획재정부/기재부» 표기 (G-20 2차)
#
# 운영 읽기 전용 스캔: Topic 63 · Guide 7 · AuditCase 9 = 79건. 발생 위치마다 앞뒤 30자 문맥으로 소관을 가른다.
#   · 계약·적격심사·입찰·낙찰 문맥 → 재정경제부 (국가계약법·계약예규 소관)
#   · 예산·보조금·보조사업·총사업비·기금·집행지침 문맥 → 기획예산처 (예산 편성·집행, e나라도움 = 기획예산처 운영)
#   · 유류비·여비 문맥 → 변경하지 않음 (여비 소관 미확인, NEEDS_REVIEW)
#   · 그 밖(국유재산·국고·회계·공공기관 등) → 재정경제부
# 문맥 판정은 계약 우선. «기획재정부장관» 은 부처명 치환으로 «재정경제부장관/기획예산처장관» 이 된다.
# 멱등: 옛 명칭이 남지 않으면 두 번째 실행은 변경 0. DRY_RUN=1 이면 집계만 출력하고 쓰지 않는다.

old_name   = /기획재정부|기재부/
window     = 30
skip_re    = /유류비|여비/
contract_re = /계약|적격심사|입찰|낙찰/
budget_re  = /예산|보조금|보조사업|국고보조|총사업비|기금|집행지침/

classify = lambda do |text, pos, len|
  ctx = text[[ pos - window, 0 ].max, window * 2 + len]
  if skip_re.match?(ctx) then :skip
  elsif contract_re.match?(ctx) then "재정경제부"
  elsif budget_re.match?(ctx) then "기획예산처"
  else "재정경제부"
  end
end

counts = Hash.new(0)
rename_string = lambda do |text|
  return text unless text.is_a?(String) && old_name.match?(text)

  out = +""
  last = 0
  text.to_enum(:scan, old_name).map { Regexp.last_match }.each do |m|
    out << text[last...m.begin(0)]
    target = classify.call(text, m.begin(0), m[0].length)
    counts[target] += 1
    out << (target == :skip ? m[0] : target)
    last = m.end(0)
  end
  out << text[last..]
  out
end

deep = lambda do |value|
  case value
  when String then rename_string.call(value)
  when Array  then value.map { |v| deep.call(v) }
  when Hash   then value.transform_values { |v| deep.call(v) }
  else value
  end
end

dry_run = ENV["DRY_RUN"] == "1"
ActiveRecord::Base.transaction do
  [ Topic, Guide, AuditCase ].each do |klass|
    text_cols = klass.columns.select { |c| %i[string text json jsonb].include?(c.type) }.map(&:name) - %w[slug]
    klass.find_each do |record|
      changes = {}
      text_cols.each do |col|
        before = record.read_attribute(col)
        after = deep.call(before)
        changes[col] = after if after != before
      end
      record.update_columns(changes.merge(updated_at: Time.current)) if changes.any? && !dry_run
    end
  end
  puts "  [ministry-rename] #{dry_run ? 'DRY_RUN ' : ''}재정경제부=#{counts['재정경제부']} 기획예산처=#{counts['기획예산처']} skip=#{counts[:skip]}"
end
