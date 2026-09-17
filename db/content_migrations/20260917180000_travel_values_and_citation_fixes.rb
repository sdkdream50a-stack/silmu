# 여비 구기준 잔존값·오인용 조문 정정 (2026-09-17 전수감사 G-37 1차)
#
# G-10(20260917121000)은 본문 텍스트만 고쳤고 jsonb(faqs·quick_stats)와 가이드 sections 에 구기준이 남았다.
# 근거: 공무원 여비 규정 별표 2(2026.6.30. 개정) — 일비·식비 1일 각 25,000원(직급 차등 없음),
#       숙박비 실비·상한 서울 100,000 · 광역시 80,000 · 그 밖 70,000원. 제16조 = 일비ㆍ숙박비ㆍ식비의 지급.
#       국가공무원법 제48조 = 실비 변상 등. 지방계약법 시행령 제67조 = 대가의 지급, 제92조 = 부정당업자의 입찰 참가자격 제한.
# 각 치환은 대상 문자열이 있어야 하고(없으면 전체 롤백), 이미 새 문자열이면 건너뛴다. DRY_RUN=1 이면 쓰지 않는다.

subs = [
  [ Topic, "travel-expense-settlement", :faqs, [
    [ "일비는 직급 공통 1일 20,000원, 식비는 4급 이상 1일 25,000원·5급 이하 20,000원으로 정산합니다.",
      "일비·식비는 직급 구분 없이 1일 각 25,000원으로 정산합니다(공무원 여비 규정 별표 2)." ],
    [ "국가공무원법 제48조(여비)의 위임", "국가공무원법 제48조(실비 변상 등)의 위임" ]
  ] ],
  [ Topic, "travel-expense-settlement", :quick_stats, [
    [ "2만원/일", "2.5만원/일" ],
    [ "5급 이하 2만원", "직급 공통" ]
  ] ],
  [ Topic, "domestic-travel-allowance", :quick_stats, [
    [ "2만원/일", "2.5만원/일" ],
    [ "5급 이하 2만원", "직급 공통" ],
    [ "5급 이하 6만원", "실비 · 공무원 여비 규정 별표 2" ],
    [ "7만원/일", "서울 10만·광역시 8만·그 밖 7만원" ]
  ] ],
  [ Topic, "domestic-travel-allowance", :faqs, [
    [ "직급에 관계없이 1일 20,000원입니다.", "직급에 관계없이 1일 25,000원입니다(공무원 여비 규정 별표 2)." ],
    [ "식비는 4급 이상 1일 25,000원, 5급 이하 20,000원입니다. 숙박비 상한은 4급 이상 70,000원, 5급 이하 60,000원이며 실비로 지급됩니다.",
      "식비는 직급 구분 없이 1일 25,000원입니다. 숙박비는 실비로 지급하며 상한은 서울 100,000원·광역시 80,000원·그 밖 70,000원입니다." ],
    [ "공무원여비규정 제16조(국내 여비의 지급 기준) 및 동 규정 별표(직급별 여비 기준)에 따릅니다.",
      "공무원 여비 규정 제16조(일비ㆍ숙박비ㆍ식비의 지급) 및 별표 2(국내 여비 지급표)에 따릅니다." ]
  ] ],
  [ Guide, "travel-expense-complete-2", :sections, [
    [ "출장 다녀온 선배가 식비 2만5천 원을 받았는데, 저는 2만 원밖에 안 나왔습니다. 같은 식당을 갔는데 왜 다를까요? 직급이 달랐기 때문입니다. 여비는 직급에 따라 다릅니다. 오늘 이 기준을 완벽히 정리합니다.",
      "출장 여비의 일비·식비가 직급마다 다르다고 알고 있는 분이 많습니다. 현행 공무원 여비 규정 별표 2는 일비·식비를 직급 구분 없이 1일 각 25,000원으로 정합니다. 오늘 이 기준을 정리합니다." ],
    [ "국내 여비 지급 기준표 — 직급별 일비·식비·숙박비 금액 규정", "국내 여비 지급표 — 일비·식비·숙박비 상한 금액 규정" ],
    [ "【실제 감사 지적 사례】 B 교육청 담당자가 6급임에도 불구하고 시스템 설정 오류로 5급 기준 식비를 2년간 지급받았습니다. 감사에서 초과 지급분 전액(약 18만 원) 반납 처분을 받았습니다. 시스템 오류라도 본인이 확인했어야 했다는 판단이었습니다.",
      "【확인 사항】 현행 별표 2에는 직급별 일비·식비 차등이 없습니다. 여비 시스템에 직급별 식비 같은 이전 설정값이 남아 있지 않은지 확인하세요." ]
  ] ],
  [ Guide, "suui-contract-complete-5", :sections, [
    [ "지방계약법 시행령 제92조", "지방계약법 시행령 제67조" ],
    [ "대금 지급 기한 및 절차", "대가의 지급 — 검사 완료 후 청구를 받은 날부터 5일 이내" ]
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
  puts "  [g37-travel-citation] #{dry_run ? 'DRY_RUN ' : ''}substitutions=#{applied}"
  raise ActiveRecord::Rollback if dry_run
end
