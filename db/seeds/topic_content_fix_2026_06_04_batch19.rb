# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치19 (제N조 의미오기 감사 #14: budget 클러스터)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04):
#   지방재정법(본법) §36=예산의 편성·§41=예산의 과목 구분·§45=추가경정예산·§47=목적 외 사용금지·§47의2=이용·이체·§49=전용 (§53·§66 부존재).
#   지방회계법(본법) §7=출납 폐쇄기한·§14=결산의 수행·§29=지출원인행위·§46=회계관계공무원의 임명 또는 위임.
#   지방재정법 시행령 §37=(공란)·§38=기준부담률 의견제시·§47=예산의 과목구분 및 설정. (예산편성기준=행안부「지방자치단체 예산편성 운영기준」 예규)
#   지방자치법(현행 286501) §142=예산의 편성 및 의결·§54=임시회 (§127=사업소·§144=예비비·§56=개회휴회폐회 → 인용 오기).
#
# 결함·정정:
#   ① accounting-officers.law: 지방회계법§46 "(법령상 정의)" → "(회계관계공무원의 임명 또는 위임)" (§46 실제 제목).
#   ② budget-compilation.law: 지방자치법§127(=사업소)→§142(예산의 편성 및 의결) · 관련법령 시행령§37/§38(가공)→예규+자치법§142.
#   ③ budget-compilation.decree: 시행령§37(예산편성기준)·§38(편성절차)=가공(실제 시행령§37 공란·§38 기준부담률) → 행안부 예규+지방재정법§36 REFRAME.
#   ④ budget-settlement.law: 지방재정법§53(결산)·§66(출납폐쇄)=부존재 → 지방회계법§14(결산의 수행)·§7(출납 폐쇄기한). (일수 보존)
#   ⑤ budget-transfer.law: §47(이용·전용)=목적외사용금지 → §47의2(이용·이체)+§49(전용). ②의 국가재정법 용어(중앙관서장·기재부장관)→지방.
#   ⑥ supplementary-budget.law: 지방자치법§144(=예비비)→§142·§56(=개회휴회)→§54(임시회). (§45 추경=정확 유지)
# ⛔ 무수정(오탐 확인): budget-compilation-guideline·budget-item-standard(시행령§47=과목구분 정확)·budget-execution(지방회계법§29=지출원인행위)·extra-budgetary-fund(시행령§51/§52 정확).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "eval(Base64.decode64(...))"'

fixes = [
  [ "accounting-officers", "law_content", [
    [ "**[지방] 지방회계법 제46조 (\"회계관계공무원\"의 법령상 정의)**", "**[지방] 지방회계법 제46조 (회계관계공무원의 임명 또는 위임)**" ]
  ] ],
  [ "budget-compilation", "law_content", [
    [ "<p><strong>지방자치법 제127조 (예산안의 편성 및 의결)</strong></p>", "<p><strong>지방자치법 제142조 (예산의 편성 및 의결)</strong></p>" ],
    [ "지방자치법 제127조는 예산안 편성 및 의회 제출·의결 기한을 규정합니다.", "지방자치법 제142조는 예산안 편성 및 의회 제출·의결 기한을 규정합니다." ],
    [ "<strong>관련 법령:</strong> 지방재정법 제36조 (예산의 편성), 지방재정법 시행령 제37조 (예산편성기준), 제38조 (예산의 편성절차)", "<strong>관련 법령:</strong> 지방재정법 제36조 (예산의 편성), 지방자치법 제142조 (예산의 편성 및 의결), 행정안전부 「지방자치단체 예산편성 운영기준」" ]
  ] ],
  [ "budget-compilation", "decree_content", [
    [ "<p><strong>지방재정법 시행령 제37조 (예산편성기준)</strong></p>", "<p><strong>행정안전부 「지방자치단체 예산편성 운영기준」 (예산편성기준)</strong></p>" ],
    [ "<p style='margin-top:20px'><strong>지방재정법 시행령 제38조 (예산의 편성절차)</strong></p>", "<p style='margin-top:20px'><strong>예산편성 절차 (지방재정법 제36조)</strong></p>" ],
    [ "① 지방자치단체의 장은 제37조의 예산편성기준에 따라 그 지방자치단체의 예산편성지침을 작성하여 각 부서에 통보하여야 한다.", "① 지방자치단체의 장은 행정안전부의 예산편성기준에 따라 그 지방자치단체의 예산편성지침을 작성하여 각 부서에 통보하여야 한다." ]
  ] ],
  [ "budget-settlement", "law_content", [
    [ "## 지방재정법 제53조 (결산)", "## 결산 (지방회계법 제14조)" ],
    [ "**지방재정법 제53조 (결산)**", "**지방회계법 제14조 (결산의 수행)**" ],
    [ "**출납 폐쇄 시기 (지방재정법 제66조)**", "**출납 폐쇄 시기 (지방회계법 제7조)**" ]
  ] ],
  [ "budget-transfer", "law_content", [
    [ "## 지방재정법 제47조 (예산의 이용·전용)", "## 예산의 이용·이체·전용 (지방재정법 제47조의2·제49조)" ],
    [ "**지방재정법 제47조 (예산의 이용·전용)**", "**지방재정법 제47조의2 (예산의 이용·이체)·제49조 (예산의 전용)**" ],
    [ "② 각 중앙관서의 장은 예산의 목적 범위 안에서 재원의 효율적 활용을 위하여 대통령령이 정하는 바에 따라 기획재정부장관의 승인을 얻어 각 세항 또는 목의 금액을 전용(轉用)할 수 있다.", "② 지방자치단체의 장은 예산의 목적 범위에서 재원의 효율적 활용을 위하여 대통령령으로 정하는 바에 따라 각 정책사업 내 단위사업 또는 목의 금액을 전용(轉用)할 수 있다." ]
  ] ],
  [ "supplementary-budget", "law_content", [
    [ "지방자치법 제144조(예산안의 편성 및 의결) 및 제56조(임시회)", "지방자치법 제142조(예산의 편성 및 의결) 및 제54조(임시회)" ]
  ] ]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  content = topic.public_send(field).to_s
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end
puts "[content_fix batch19] #{results.join(' | ')}"

puts "--- 잔존 검증 (가공/오기 0이어야) ---"
checks = {
  [ "accounting-officers", "law_content" ] => [ "제46조 (\"회계관계공무원\"의 법령상 정의)" ],
  [ "budget-compilation", "law_content" ] => [ "지방자치법 제127조", "시행령 제37조 (예산편성기준)" ],
  [ "budget-compilation", "decree_content" ] => [ "지방재정법 시행령 제37조 (예산편성기준)", "지방재정법 시행령 제38조 (예산의 편성절차)" ],
  [ "budget-settlement", "law_content" ] => [ "지방재정법 제53조", "지방재정법 제66조" ],
  [ "budget-transfer", "law_content" ] => [ "제47조 (예산의 이용·전용)", "중앙관서의 장", "기획재정부장관" ],
  [ "supplementary-budget", "law_content" ] => [ "제144조", "제56조(임시회)" ]
}
checks.each do |(slug, field), pats|
  t = Topic.find_by(slug: slug); next unless t
  c = t.public_send(field).to_s
  pats.each do |p|
    n = c.scan(p).size
    puts "  #{slug}.#{field} '#{p}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
  end
end
# 정정 앵커 출현
{ "budget-settlement"=>[ "지방회계법 제14조", "지방회계법 제7조" ], "budget-transfer"=>[ "제47조의2", "제49조" ], "supplementary-budget"=>[ "제142조", "제54조" ], "budget-compilation"=>[ "제142조", "예산편성 운영기준" ] }.each do |slug, pats|
  t=Topic.find_by(slug: slug); next unless t
  full=(t.law_content.to_s+t.decree_content.to_s)
  puts "  #{slug} 앵커: "+pats.map { |p| "#{p}=#{full.scan(p).size}" }.join(" ")
end
