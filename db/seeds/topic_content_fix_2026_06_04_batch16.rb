# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치16 (제N조 의미오기 감사 #11: 수의계약 클러스터 REFRAME)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04, 지방계약법 본법253973·시행령286149·시행규칙285747):
#   본법 §9 = 계약의 방법(①일반입찰 원칙·단서로 수의계약 가능 / ③수의계약 대상범위·선정절차는 대통령령).
#     → 수의계약 "각 호 사유"는 본법§9에 없음(시행령§25 소관). 본법§9 괄호설명 "(수의계약)"=의미오기.
#   시행령 §25 = 수의계약에 의할 수 있는 경우(①각 호 사유) · §30 = 수의계약대상자의 선정절차 등
#     (①2인이상 견적·단서로 1인견적; §30②=지정정보처리장치) · §8②=예정가격 작성 생략 · §53=계약보증금 면제.
#   시행규칙 §25 = 제한입찰의 제한기준(소액수의 아님) · §28 = 삭제<2016.9.13> · §30 = 긴급재해복구 수의대상 ·
#     §39 = 입찰서류 작성·승낙(계약보증금 면제 아님).
#
# 결함·정정:
#   본법§9 "(수의계약)" → "(계약의 방법)"(시행령§25 병기). 가공 열거(①다음 각 호…수의계약 가능)=시행령§25 소관으로 재귀속.
#   private-contract.rule: 시행규칙§28(삭제) → 시행령§30(견적 절차 본문 일치).
#   single-quote.law: 시행령§30②(1인견적) → §30①단서.
#   small-amount-contract.rule: 시행규칙§28→시행령§30 · §39→시행령§53 · §30→시행령§8② · 사유서 근거→집행기준 예규.
#   private-contract.decree·justification.decree: 시행령§25 "(수의계약 대상)" → "(수의계약에 의할 수 있는 경우)".
# ⛔ 보류(별도 콘텐츠 정합성 패스): private-contract-amount.rule = 시행규칙§25 오기 + 금액 드리프트(공사2억/물품5천만 ↔
#   정본 종합4억·전문2억·기타1.6억·물품용역2천만) 동시결함 → 라벨만 고치면 오금액이 더 권위있게 보여 분리.
#   single-quote.decree "집행기준 제69조"=예규 조문번호 미검증으로 무수정(1인견적 근거 자체는 집행기준 정확).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "eval(Base64.decode64(...))"'

SUI9_HEADER_MD = "## 지방계약법 제9조 (계약의 방법) · 시행령 제25조 (수의계약에 의할 수 있는 경우)"
SUI9_HEADER_STRONG = "<strong>지방계약법 제9조 (계약의 방법) · 시행령 제25조 (수의계약)</strong>"
SUI9_LEADIN = "지방계약법 제9조 제1항은 일반입찰을 원칙으로 하되 단서에서 수의계약을 허용하며, 수의계약을 할 수 있는 **구체적 사유는 시행령 제25조 제1항 각 호**에서 정한다. 주요 사유는 다음과 같다."

fixes = [
  ["private-contract", "law_content", [
    ["## 지방계약법 제9조 (수의계약)", SUI9_HEADER_MD],
    ["① 지방자치단체의 장 또는 계약담당자는 계약의 목적·성질·규모 및 지역특수성 등을 고려하여 필요하다고 인정되면 다음 각 호의 어느 하나에 해당하는 경우에는 수의계약을 할 수 있다.", SUI9_LEADIN],
    ["② 수의계약의 대상·범위 및 절차 등에 관하여 필요한 사항은 대통령령으로 정한다.", "법 제9조 제3항에 따라 수의계약의 대상범위 및 상대자 선정절차 등 필요한 사항은 시행령에서 정한다."]
  ]],
  ["private-contract", "decree_content", [
    ["## 지방계약법 시행령 제25조 (수의계약 대상)", "## 지방계약법 시행령 제25조 (수의계약에 의할 수 있는 경우)"]
  ]],
  ["private-contract", "rule_content", [
    ["## 지방계약법 시행규칙 제28조 (수의계약의 절차)", "## 지방계약법 시행령 제30조 (수의계약대상자의 선정절차)"]
  ]],
  ["private-contract-justification", "law_content", [
    ["## 지방계약법 제9조 (수의계약)", SUI9_HEADER_MD],
    ["① 지방자치단체의 장 또는 계약담당자는 계약의 목적·성질·규모 및 지역특수성 등을 고려하여 필요하다고 인정되면 다음 각 호의 어느 하나에 해당하는 경우에는 **수의계약을 할 수 있다**.", SUI9_LEADIN]
  ]],
  ["private-contract-justification", "decree_content", [
    ["## 지방계약법 시행령 제25조 (수의계약 대상)", "## 지방계약법 시행령 제25조 (수의계약에 의할 수 있는 경우)"]
  ]],
  ["single-quote", "law_content", [
    ["<strong>지방계약법 제9조 (수의계약)</strong>", SUI9_HEADER_STRONG],
    ["<strong>지방계약법 시행령 제30조 제2항</strong>", "<strong>지방계약법 시행령 제30조 제1항 단서 (1인 견적)</strong>"]
  ]],
  ["small-amount-contract", "law_content", [
    ["<strong>지방계약법 제9조 (수의계약)</strong>", SUI9_HEADER_STRONG]
  ]],
  ["small-amount-contract", "rule_content", [
    ["## 지방계약법 시행규칙 — 소액수의계약 관련 규정", "## 소액수의계약 관련 규정 (지방계약법 시행령·집행기준)"],
    ["### 지방계약법 시행규칙 제28조 (수의계약의 절차)", "### 지방계약법 시행령 제30조 (수의계약대상자의 선정절차)"],
    ["### 지방계약법 시행규칙 제39조 (계약보증금 면제)", "### 지방계약법 시행령 제53조 (계약보증금의 면제)"],
    ["### 지방계약법 시행규칙 제30조 (예정가격 작성 생략)", "### 지방계약법 시행령 제8조 제2항 (예정가격 작성 생략)"],
    ["### 지방계약법 시행규칙 — 수의계약 사유서 작성 의무", "### 수의계약 사유서 작성 의무 (「지방자치단체 입찰 및 계약집행기준」)"],
    ["※ 관련 법령: 지방계약법 시행규칙 제28조·제30조·제39조", "※ 관련 법령: 지방계약법 시행령 제30조·제53조·제8조,「지방자치단체 입찰 및 계약집행기준」"]
  ]]
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
puts "[content_fix batch16] #{results.join(' | ')}"

puts "--- 잔존 검증 (틀린 인용 0이어야 함) ---"
checks = {
  "private-contract" => {
    law_content: ["## 지방계약법 제9조 (수의계약)", "다음 각 호의 어느 하나에 해당하는 경우에는 수의계약을 할 수 있다."],
    decree_content: ["제25조 (수의계약 대상)"],
    rule_content: ["시행규칙 제28조"]
  },
  "private-contract-justification" => {
    law_content: ["## 지방계약법 제9조 (수의계약)"],
    decree_content: ["제25조 (수의계약 대상)"]
  },
  "single-quote" => { law_content: ["제9조 (수의계약)", "시행령 제30조 제2항"] },
  "small-amount-contract" => {
    law_content: ["제9조 (수의계약)"],
    rule_content: ["시행규칙 제28조", "시행규칙 제39조", "시행규칙 제30조", "시행규칙 제28조·제30조·제39조"]
  }
}
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pats|
    pats.each do |pat|
      n = t.public_send(f).to_s.scan(pat).size
      puts "  #{slug}.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
    end
  end
end
