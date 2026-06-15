# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치4 (전수 "제N조의M" 인용 검증 → 부존재 14건 + 오기 1건)
# 2026-06-04. 전 토픽·전 콘텐츠필드+faqs에서 "제N조의M" 인용을 전수 추출 후 korean-law MCP로
# 실존 검증. 부존재/오기 조문만 외과적 정정(HTML·내용 보존).
# cf. [[project_topic_content_defects_2026_06_03]] (배치1 1a614fb·배치2 afc283e·배치3 ba59a8b).
#
# 검증 근거(korean-law MCP, 2026-06-04, 단건 실측):
#   지방계약법(법,mst253973): §14=계약서작성·성립(§14②=전자계약)·§22=물가변동등 계약금액조정·
#     §31의2=이의신청(실존). §14의2·§22의2 = **부존재**.
#   지방계약법 시행령(mst286149): §48=동일가격입찰·§50=계약서생략·§51=이행보증·§64=검사조서생략(3천만)·
#     §67=대가지급(5일)·§68=대가지급지연이자·§74=설계변경 계약금액조정·§90=지연배상금.
#     §49의2·§65의2·§68의2·§74의2 = **부존재**.
#   초중등교육법(법,mst279605)§33+시행령(mst286321)§64 = 학교발전기금. 초중등 시행령 §65의2 = **부존재**.
#   소득세법(법,mst285523)§140=근로소득자 소득공제 신고. 소득세법 시행규칙(mst286379) §100의2·§55의2 = **부존재**.
#   지방재정법(법,mst281909)§60의2 = **통합공시**(복식부기 아님). 복식부기·발생주의 회계기준 = 지방회계법
#     (법,mst276363)§12(지방회계기준).
#
# 🛡️ 정정 매트릭스(부존재/오기 조문번호만 교체):
#   e-bidding: 법 §14의2(전자계약)→§14②  /  시행령 §49의2(전자계약)→법 §14②·전자조달법
#   design-change: 법 §22의2(물가변동조정)→§22  /  시행령 §65의2(설계변경범위)→시행령 §74(설계변경 조정)
#   contract-execution: 시행령 §49의2(계약체결기한)→법 §14·집행기준 예규(시행령에 10일기한 조문 없음)
#   payment: 시행령 §68의2(지연이자)→§68
#   penalty-reduction-procedure: 시행령 §74의2(지체상금)→§90(지연배상금)·요율은 시행규칙 §75
#   school-budget-compilation: 초중등 시행령 §65의2(학교발전기금)→§64
#   year-end-settlement: 소득세법 시행규칙 §100의2(의료비 증명)·§55의2(주택공제 증명)=부존재 →
#     소득세법 §140·국세청 간소화로 reframe(배치3에서 §47의2→§140 기정정)
#   local-government-accounting: 지방재정법 §60의2(=통합공시) 복식부기 오인용 → 지방회계법 §12(지방회계기준)
# ⛔ 정정 제외(실존 확인): price-escalation 하도급법 §16의2 / bid-qualification §31의2 / bidding·bid-announcement·
#   cost-calculation-guide 지방계약법 §9의2(구매규격 사전공개) / 기타 국가·지방공무원법·수당규정·임용령·
#   사립학교법·보조금법·정보공개법 등 표준 의N 조문.
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch4.rb})"'

fixes = [
  [ "e-bidding", "law_content", [
    [ "지방계약법 제14조의2", "지방계약법 제14조제2항" ]
  ] ],
  [ "e-bidding", "decree_content", [
    [ "### 제49조의2 (전자계약)", "### 전자계약 (지방계약법 제14조제2항·전자조달법)" ]
  ] ],
  [ "design-change", "law_content", [
    [ "제22조의2", "제22조" ]
  ] ],
  [ "design-change", "decree_content", [
    [ "### 제65조의2 (설계변경의 범위 제한)", "### 제74조 (설계 변경으로 인한 계약금액의 조정)" ]
  ] ],
  [ "design-change", "interpretation_content", [
    [ "시행령 제65조의2", "시행령 제74조" ]
  ] ],
  [ "contract-execution", "decree_content", [
    [ "### 제49조의2 (계약 체결 기한)", "### 계약 체결 기한 (지방계약법 제14조·집행기준 예규)" ]
  ] ],
  [ "contract-execution", "interpretation_content", [
    [ "시행령 제49조의2", "지방계약법 제14조·행정안전부 예규(지방자치단체 입찰 및 계약집행기준)" ]
  ] ],
  [ "payment", "decree_content", [
    [ "### 제68조의2 (지연이자)", "### 제68조 (대가 지급 지연 이자)" ]
  ] ],
  [ "penalty-reduction-procedure", "law_content", [
    [ "법률(제30조) → 시행령(제74조의2) → 집행기준", "법률(제30조) → 시행령(제90조) → 시행규칙(제75조)·집행기준" ]
  ] ],
  [ "penalty-reduction-procedure", "decree_content", [
    [ "## 지방계약법 시행령 제74조의2 (지체상금)", "## 지방계약법 시행령 제90조 (지연배상금)" ]
  ] ],
  [ "school-budget-compilation", "decree_content", [
    [ "### 제65조의2(학교발전기금)", "### 제64조(학교발전기금)" ]
  ] ],
  [ "year-end-settlement", "rule_content", [
    [ "### 소득세법 시행규칙 제100조의2 (의료비 세액공제 증명)", "### 의료비 세액공제 증명서류 (소득세법 제140조·국세청 간소화)" ],
    [ "**제100조의2 (의료비 공제 대상 증명)**", "**의료비 공제 대상 증명**" ],
    [ "### 소득세법 시행규칙 제55조의2 (주택 관련 공제 증명)", "### 주택 관련 공제 증명서류 (소득세법 제140조·국세청 간소화)" ],
    [ "**제55조의2 (주택임차차입금 원리금 상환 증명)**", "**주택임차차입금 원리금 상환 증명**" ]
  ] ],
  [ "local-government-accounting", "law_content", [
    [ "지방재정법 제60조의2 (복식부기 회계)", "지방회계법 제12조 (지방회계기준·복식부기)" ]
  ] ]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"
    next
  end
  content = topic.public_send(field).to_s
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s)
      matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end

puts "[content_fix batch4] #{results.join(' | ')}"

# 잔존 부존재 조문 검증 (실존 조문은 제외 — 해당 토픽/필드에 한정)
puts "--- 잔존 검증 ---"
checks = {
  "e-bidding"                   => { law_content: "제14조의2", decree_content: "제49조의2" },
  "design-change"               => { law_content: "제22조의2", decree_content: "제65조의2", interpretation_content: "제65조의2" },
  "contract-execution"          => { decree_content: "제49조의2", interpretation_content: "제49조의2" },
  "payment"                     => { decree_content: "제68조의2" },
  "penalty-reduction-procedure" => { law_content: "제74조의2", decree_content: "제74조의2" },
  "school-budget-compilation"   => { decree_content: "제65조의2" },
  "year-end-settlement"         => { rule_content: "제100조의2" },
  "local-government-accounting" => { law_content: "제60조의2" }
}
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pat|
    n = t.public_send(f).to_s.scan(pat).size
    puts "  #{slug}.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
  end
end
# year-end §55의2 별도
ye = Topic.find_by(slug: "year-end-settlement")
puts "  year-end-settlement.rule_content '제55조의2' 잔존=#{ye.rule_content.to_s.scan('제55조의2').size}" if ye
