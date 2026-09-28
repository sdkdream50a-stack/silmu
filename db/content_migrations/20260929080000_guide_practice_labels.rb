# Guide 실무 라벨 4건 — 근거 없는 순위·의무 표현에 «실무 절차/예시» 라벨 부착(2026-09-29)
#
# LABEL-ONLY: 새 법적 주장·SEO(title/slug/description) 변경 없음. 기존 서술의 근거 강도만 명확히 한다.
#   budget-execution-complete-5 why_it_matters: «감사원 지적 1위 유형» — 출처 없는 순위 통계 → «감사에서 자주 지적되는 유형»으로 중립화.
#   budget-execution-complete-7 step3.title: «예비비 신청 절차 (5단계)» — 신청·승인 세부 절차는 운영기준에 조문 없음(#157/20260929050000 R-budget
#     결정과 동일 근거) → «(5단계 · 실무 절차 — 기관별 상이)» 라벨 부착. sections jsonb 단일 leaf라 목차(show.html.erb TOC)도 같이 바뀐다.
#   budget-execution-complete-8 step3.title: «불용액 처리 절차 (5단계)» — 같은 사유로 «(실무 절차 — 기관별 상이)» 부착.
#   hr-welfare-complete-9 step1.title: «지적 사례 1~3위: 금전 관련 3대 유형» — TOP10 순위는 공식 통계가 아니라 실무 경험 기반 예시 →
#     «(순위는 실무 경험에 따른 예시이며 공식 통계가 아님)» 라벨 부착. 순번(1~3위 등)·유형 구성은 그대로(재배열 없음).
#
# old 는 운영 페이지(https://silmu.kr/guides/<slug>?cb=…, 2026-09-29 익명 GET)의 렌더 문자열과 seed(db/seeds/*)가 같음을 확인했다.
# edits 는 필드(jsonb 문자열 leaf 합계)에 old 가 정확히 1회 있어야 바꾼다. 이미 new 면(= new 가 old 를 포함) 건너뛴다.
# 하나라도 어긋나면 전체 롤백. DRY_RUN=1 이면 레코드별 fields_to_change 만 출력한다. view_count·slug·title·description 불변.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929080000_guide_practice_labels.rb})"'
#   → 기대: changes=4 (budget-execution-complete-5 sections 1 · -7 sections 1 · -8 sections 1 · hr-welfare-complete-9 sections 1)
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화) → 재실행 시 changes=0
# 롤백: 아래 edits 의 new → old 역적용.

edits = [
  [ "budget-execution-complete-5", "sections",
    "선집행은 감사원 지적 1위 유형 중 하나입니다",
    "선집행은 감사에서 자주 지적되는 유형입니다" ],
  [ "budget-execution-complete-7", "sections",
    "예비비 신청 절차 (5단계)",
    "예비비 신청 절차 (5단계 · 실무 절차 — 기관별 상이)" ],
  [ "budget-execution-complete-8", "sections",
    "불용액 처리 절차 (5단계)",
    "불용액 처리 절차 (5단계) (실무 절차 — 기관별 상이)" ],
  [ "hr-welfare-complete-9", "sections",
    "지적 사례 1~3위: 금전 관련 3대 유형",
    "지적 사례 1~3위: 금전 관련 3대 유형 (순위는 실무 경험에 따른 예시이며 공식 통계가 아님)" ]
].freeze

count_in = lambda do |value, needle|
  case value
  when String then value.scan(needle).size
  when Array  then value.sum { |v| count_in.call(v, needle) }
  when Hash   then value.values.sum { |v| count_in.call(v, needle) }
  else 0
  end
end

replace_in = lambda do |value, from, to|
  case value
  when String then value.gsub(from) { to }
  when Array  then value.map { |v| replace_in.call(v, from, to) }
  when Hash   then value.transform_values { |v| replace_in.call(v, from, to) }
  else value
  end
end

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  edits.each do |slug, field, old, new|
    guide = Guide.find_by(slug: slug)
    next unless guide

    value = guide.read_attribute(field)
    value = value.deep_stringify_keys if value.is_a?(Hash)
    next if count_in.call(value, new).positive? && (count_in.call(value, old).zero? || new.include?(old))
    raise "[guide-practice-labels] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

    puts "  [guide-practice-labels] Guide/#{slug} fields_to_change=#{field}"
    changes += 1
    guide.update_columns(field => replace_in.call(value, old, new), "updated_at" => Time.current) unless dry
  end
end
puts "  [guide-practice-labels] #{"DRY_RUN " if dry}changes=#{changes}"
