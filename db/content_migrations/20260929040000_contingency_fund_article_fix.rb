# Topic contingency-fund — 예비비 사용 요건의 근거로 적힌 «지방재정법 시행령 제65조» 정정(2026-09-29)
#
# 시행령 제65조는 «재정분석 및 재정점검»(행정안전부장관의 재정보고서 분석·재정위험 점검) 조문으로 예비비와 무관하다.
# 예비비의 법률 근거는 지방재정법 제43조다. 제43조제1항은 «예측할 수 없는 예산 외의 지출 또는 예산 초과 지출에 충당»만 정하고,
# 긴급성·전용/이용 불가·목적 적합성은 법·시행령 조문에 없다(시행령의 예비비 조문은 제48조 계상 제한·제56조제3항 배정뿐)
# → 조문 번호는 확인된 제43조제1항으로 바꾸고, 나머지 요건은 «실무 검토 사항»으로 중립 서술한다.
# 같은 근거로 법령에 없는 의무 문구 2건도 실무 서술로: FAQ «신규 사업 추진 … 사용할 수 없습니다» → 실무상 추경 처리가 일반적
# (의회 삭감 항목 사용 금지는 제43조제3항 원문대로 법적 서술 유지) · 요약 카드 «… 모두 충족» → 법(예측 불가)과 실무 검토 구분.
# 같은 페이지의 남은 의무 문구 3곳(2026-09-29 3차):
#   Guide budget-execution-complete-7 (토픽 «절차» 탭에 임베드) step2 «세 요건을 모두 충족 … 하나라도 빠지면 불가»
#     → 법 제43조제1항(예측 불가)만 법적 요건, 긴급성·불가피성은 «실무 검토 요건».
#   Topic rule_content «❌ 사용 불가 사례 · 신규 사업 추진을 위한 예산 확보» → 법령 금지 조항 없음 · 실무상 추경 대상.
#   Topic regulation_content «예비비 사용 제한 사항 (행안부 지침)» — 「지방자치단체 예산편성 운영기준」(행정안전부 훈령 제449호,
#     시행 2026. 6. 30.) 전문·별표에 이 4개 제한 문구가 없다(NOT_FOUND). 오히려 별표 11(세출예산 성질별 분류) 편성목 801 예비비
#     3.은 «일반예비비는 법령에서 제한하는 경우를 제외하고 재해·재난 관련 목적(긴급재난대책을 위한 보조금 포함)을 포함한 모든
#     사업으로 사용가능» 이라 정한다 → «행안부 지침» 표기 삭제, 의회 삭감 항목은 법 제43조제3항으로, 나머지는 «(실무 관행)».
#     원문: https://www.law.go.kr/DRF/lawService.do?OC=test&target=admrul&ID=2100000281550&type=XML
# 4차(Topic regulation_content 수치·조문):
#   «일반예비비 … 1/100 이상» → 법 제43조① «예산 총액의 100분의 1 이내».
#   «목적예비비 … 특정 목적 · 세출예산 총액의 2/100 이내» → 법 제43조② «재해ㆍ재난 관련 목적 예비비는 별도로 예산에 계상할 수 있다»,
#     운영기준 별표 11 편성목 801 «02. 재해·재난목적예비비 … 제43조제2항에 따른 예비비(예비비 편성 한도는 없음)». 2/100 근거 없음.
#   «시행령 제59조»(삭제 <2016.11.29>) → 시행령 제56조③ «예비비의 지출을 결정한 때에는 세출예산으로서 배정하여야 한다».
# 원문: 지방재정법 [MST 283145, 시행 2026. 7. 1.] 제43조
#       https://www.law.go.kr/DRF/lawService.do?OC=test&target=law&MST=283145&type=XML
#       지방재정법 시행령 [MST 281539, 시행 2026. 1. 2.] 제65조(재정분석 및 재정점검)·제48조·제56조
#       https://www.law.go.kr/DRF/lawService.do?OC=test&target=law&MST=281539&type=XML
# 운영 옛 값: https://silmu.kr/topics/contingency-fund 익명 GET(2026-09-29) — FAQ 답변(본문·FAQPage JSON-LD)·요약 카드 note 2곳.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929040000_contingency_fund_article_fix.rb})"'
#   → 기대: changes=19 (edit 단위 집계 — Topic faqs 2 · quick_stats 2 · rule_content 1 · regulation_content 9 · Guide sections 5)
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화) → 재실행 시 changes=0
#
# 동작: 필드별 old 가 정확히 1회 있어야 바꾼다. 이미 new 이면(new 가 old 를 품는 edit 포함) 건너뛴다. 하나라도 어긋나면 전체 롤백.
# DRY_RUN=1 이면 바꿀 필드만 출력하고 쓰지 않는다. view_count 는 건드리지 않는다. 롤백: 같은 표의 new → old 역적용.

slug = "contingency-fund"
guide_slug = "budget-execution-complete-7"

edits = [
  [ Topic, slug, "faqs",
    "예측 불가능성, 긴급성, 기존 예산의 전용·이용으로 해결 불가, 목적 적합성 요건을 모두 충족해야 사용할 수 있습니다(지방재정법 시행령 제65조).",
    "지방재정법 제43조제1항은 예비비를 「예측할 수 없는 예산 외의 지출 또는 예산 초과 지출」에 충당하도록 정하고 있습니다. 긴급성, 기존 예산의 전용·이용으로 해결 불가, 목적 적합성은 실무에서 함께 검토하는 사항입니다." ],
  [ Topic, slug, "faqs",
    "신규 사업 추진이나 의회가 삭감한 사업에는 예비비를 사용할 수 없습니다.",
    "지방의회의 예산안 심의 결과 폐지되거나 감액된 지출항목에는 예비비를 사용할 수 없습니다(같은 조 제3항). 신규 사업은 실무상 예비비 대신 추가경정예산으로 처리하는 것이 일반적입니다." ],
  [ Topic, slug, "quick_stats",
    "지방재정법 시행령 제65조",
    "지방재정법 제43조제1항(예측할 수 없는 지출) · 그 밖의 요건은 실무 기준" ],
  [ Topic, slug, "quick_stats",
    "예측불가·긴급·예산부족·목적적합 모두 충족",
    "예측할 수 없는 지출(법) · 긴급·예산부족·목적적합(실무 검토)" ],
  [ Topic, slug, "rule_content",
    "신규 사업 추진을 위한 예산 확보",
    "신규 사업 추진을 위한 예산 확보 (실무 관행 — 법령상 금지 조항은 없으나 실무상 추경 대상)" ],
  [ Topic, slug, "regulation_content",
    "예비비 사용 제한 사항 (행안부 지침)",
    "예비비 사용 제한 사항 (법령 및 실무 관행)" ],
  [ Topic, slug, "regulation_content",
    "의회 의결로 삭감된 사업에 예비비 지원 금지",
    "지방의회의 예산안 심의 결과 폐지되거나 감액된 지출항목에는 예비비 사용 불가 (지방재정법 제43조제3항)" ],
  [ Topic, slug, "regulation_content",
    "인건비 예비비 사용은 법령상 의무 지출 증가에 한정",
    "(실무 관행) 인건비는 법령상 의무 지출 증가분 위주로 예비비 사용을 검토" ],
  [ Topic, slug, "regulation_content",
    "신규 사업은 원칙적으로 추경 편성 대상 (예비비 사용 부적합)",
    "(실무 관행) 신규 사업은 통상 추경으로 편성 — 「지방자치단체 예산편성 운영기준」 별표 11은 일반예비비를 «법령에서 제한하는 경우를 제외하고 … 모든 사업으로 사용가능» 이라 정함" ],
  [ Topic, slug, "regulation_content",
    "연말 집중 예비비 사용은 재정분석 감점 대상",
    "(실무 관행) 연말에 예비비를 몰아 쓰는 것은 지양" ],
  [ Topic, slug, "regulation_content",
    "일반회계 세출예산의 1/100 이상",
    "일반회계·교육비특별회계 예산 총액의 100분의 1 이내 (지방재정법 제43조제1항)" ],
  [ Topic, slug, "regulation_content",
    "특정 목적을 위해 편성",
    "재해·재난 관련 목적 예비비 (지방재정법 제43조제2항)" ],
  [ Topic, slug, "regulation_content",
    "세출예산 총액의 2/100 이내",
    "별도 계상 가능 · 편성 한도 없음 (예산편성 운영기준 별표 11 편성목 801)" ],
  [ Topic, slug, "regulation_content",
    "(지방재정법 제43조 및 시행령 제59조)",
    "(지방재정법 제43조 및 시행령 제56조제3항)" ],
  [ Guide, guide_slug, "sections",
    "예비비 사용 가능 요건 3가지",
    "예비비 사용 요건 — 법령 요건 1가지와 실무 검토 요건 2가지" ],
  [ Guide, guide_slug, "sections",
    "요건①: 예측 불가능성 — 당초 예산 편성 시 예상할 수 없었던 사유여야 함",
    "법령 요건①: 예측 불가능성 — 「예측할 수 없는 예산 외의 지출 또는 예산 초과 지출」에 충당 (지방재정법 제43조제1항)" ],
  [ Guide, guide_slug, "sections",
    "요건②: 긴급성 — 추경 편성이나 전용을 기다릴 시간적 여유가 없어야 함",
    "실무 검토 요건②: 긴급성 — 추경 편성이나 전용을 기다릴 시간적 여유가 있는지 검토" ],
  [ Guide, guide_slug, "sections",
    "요건③: 불가피성 — 다른 예산 과목으로 대체하거나 지출을 연기할 수 없어야 함",
    "실무 검토 요건③: 불가피성 — 다른 예산 과목으로 대체하거나 지출을 연기할 수 있는지 검토" ],
  [ Guide, guide_slug, "sections",
    "※ 세 요건을 모두 충족해야 예비비 사용 가능 — 하나라도 빠지면 불가",
    "※ 법령이 정한 요건은 ①이며, ②·③은 법령 조문이 아니라 예산부서가 함께 검토하는 실무 요건입니다." ]
]

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
  edits.each do |klass, rslug, field, old, new|
    record = klass.find_by(slug: rslug)
    next unless record

    value = record.read_attribute(field)
    next if count_in.call(value, new).positive? && (count_in.call(value, old).zero? || new.include?(old))
    raise "[contingency-fund] fingerprint missing: #{klass.name}/#{rslug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

    puts "  [contingency-fund] #{klass.name}/#{rslug} fields_to_change=#{field}"
    changes += 1
    record.update_columns(field => replace_in.call(value, old, new), updated_at: Time.current) unless dry
  end
end
puts "  [contingency-fund] #{"DRY_RUN " if dry}changes=#{changes}"
