# 계약보증금·입찰보증금 면제 기준 구기준·창작 정정 (2026-09-17 전수감사 G-37 3차)
#
# 원문(law.go.kr): 지방계약법 제15조 · 시행령 제37조 제3항(입찰보증금 면제 = 입찰참가자 유형, 금액 기준 없음) ·
#   제51조 제1항 제1호(공사 이행보증 — 계약보증금 100분의 10 이상) · 제52조(납부방법) · 제53조(면제: 제37조③ 해당자·계약금액 5천만원 이하·관습·외자 부분품, 확약서).
# 제53조 제1항 제2호는 2021.1.5. 개정 이후 5천만원이다. contract-guarantee-exemption 토픽은 «3천만원·2천만원», «상장법인·AA 등급·개산·단가·긴급계약 면제»
# 등 원문에 없는 기준으로 채워져 있어 필드 단위로 원문 근거 문안으로 바꾼다. 다른 두 토픽은 줄 단위 치환.
# 필드 교체는 종전 첫 줄(fingerprint) 확인 후, 치환은 대상 문자열 확인 후 적용 — 하나라도 없으면 전체 롤백. DRY_RUN=1 이면 쓰지 않는다.

field_replacements = [
  [ :summary, "3천만원 이하 계약은 보증금 면제 가능", <<~'MD' ],
  계약보증금은 원칙적으로 내게 해야 하며(지방계약법 제15조), 계약금액 5천만원 이하 계약이나 국가기관·지방자치단체·공기업 등 시행령 제37조 제3항 해당자와의 계약 등 시행령 제53조 제1항 각 호에 해당하면 면제할 수 있습니다. 면제받은 자에게는 지급 확약서를 받습니다.
  MD
  [ :decree_content, "## 지방계약법 시행령 제53조 (계약보증금 면제)", <<~'MD' ],
  ## 지방계약법 시행령 계약보증금 조문 (원문)

  ### 지방계약법 시행령 제52조(계약보증금 납부방법)

  ① 계약보증금은 현금 또는 제37조 제2항 각 호에 규정된 보증서 등으로 내게 하여야 한다.

  ② 「자본시장과 금융투자에 관한 법률 시행령」 제192조제2항에 따른 상장증권 또는 현금으로 납부된 계약보증금을 계약상대자가 특별한 사유로 제37조 제2항 제1호부터 제5호까지에 규정된 보증서 등으로 대체 납부할 것을 요청한 경우에는 그 가치에 상당하는 금액 이상으로 대체 납부하게 할 수 있다.

  ### 지방계약법 시행령 제53조(계약보증금 면제)

  ① 법 제15조 제1항 단서에 따라 계약보증금을 면제할 수 있는 경우는 다음 각 호와 같다.
  1. 제37조 제3항 제1호부터 제5호까지 및 제6호의2에 규정된 자와 계약을 체결하는 경우
  2. 계약금액이 5천만원 이하인 계약을 체결하는 경우
  3. 일반적으로 공정ㆍ타당하다고 인정되는 계약의 관습에 따라 계약보증금 징수가 적합하지 아니한 경우
  4. 이미 도입된 외국자본시설ㆍ기계ㆍ장비의 부분품을 구매하는 경우로서 해당 공급자가 아니면 그 부분품의 구입이 곤란한 경우

  ② 지방자치단체의 장 또는 계약담당자는 제1항에 따라 계약보증금의 납부를 면제받은 자에게 법 제15조 제3항에 따른 계약보증금의 세입조치 사유가 발생한 경우 계약보증금에 해당하는 금액을 낼 것을 보장하기 위하여 그 지급을 확약하는 내용의 문서(이하 이 조에서 “확약서”라 한다)를 제출하게 하여야 한다. 다만, 제1항제3호에 해당하는 경우에는 확약서 제출을 생략하게 할 수 있다.

  > 원문: 국가법령정보센터(law.go.kr) 지방계약법 시행령 [시행일 2026.06.03] — 2026-09-17 대조. 개정 연혁 표기는 생략했습니다.
  MD
  [ :rule_content, "## 입찰 및 계약집행기준 (예규 제332호)", <<~'MD' ],
  ## 입찰 및 계약 집행기준

  종전에 이 탭에 실린 «소액 계약 3천만원 이하 면제», «상장법인·신용평가 AA 이상 면제», «개산·단가·긴급계약 면제» 등은 법령·예규 원문에서 확인되지 않아 내렸습니다(2026-09-17). 면제 사유는 지방계약법 시행령 제53조 제1항(시행령 탭)에서 정한 경우로 판단하세요.
  MD
  [ :regulation_content, "## 행정안전부 예규 (지방자치단체 입찰 및 계약집행기준)", <<~'MD' ],
  ## 행정안전부 예규

  종전에 이 탭에 실린 «공사 3천만원 미만·물품·용역 2천만원 미만 면제», «이행 실적 우수·신용등급 양호 시 면제», «선금 미지급 계약 면제» 등은 법령·예규 원문과 맞지 않아 내렸습니다(2026-09-17). 예규 원문을 대조한 뒤 다시 싣습니다.

  ### 지방계약법 제15조(계약보증금)

  ① 지방자치단체의 장 또는 계약담당자는 지방자치단체와 계약을 체결하려는 자로 하여금 계약보증금을 내도록 하여야 한다. 다만, 다른 지방자치단체, 공공기관 및 지방공기업 등 대통령령으로 정하는 계약상대자에 대하여는 계약보증금의 납부를 면제할 수 있다.

  ② 제1항에 따른 계약보증금의 금액ㆍ납부방법, 그 밖에 필요한 사항은 대통령령으로 정한다.

  ③ 지방자치단체의 장 또는 계약담당자는 계약상대자가 계약상의 의무를 이행하지 아니하면 그 계약보증금을 해당 지방자치단체에 귀속시켜야 한다. 다만, 제1항 단서에 따라 계약보증금의 납부를 면제한 경우에는 대통령령으로 정하는 바에 따라 계약상대자로 하여금 계약보증금에 해당하는 금액을 해당 지방자치단체에 내도록 하여야 한다.
  MD
  [ :practical_tips, "## 계약보증금 면제 실무 가이드", <<~'MD' ],
  ## 계약보증금 면제 실무 가이드

  ### ⚠️ 면제할 수 있는 경우 (지방계약법 시행령 제53조 제1항)
  - 국가기관·다른 지방자치단체, 공기업·준정부기관, 지방공사·지방공단 등 시행령 제37조 제3항 제1호~제5호·제6호의2에 해당하는 자와의 계약
  - 계약금액 **5천만원 이하** 계약
  - 공정·타당한 계약 관습상 계약보증금 징수가 적합하지 않은 경우
  - 이미 도입된 외국자본시설·기계·장비의 부분품을 해당 공급자에게서만 살 수 있는 경우

  ### ⚠️ 면제할 때
  - 면제받은 자에게 계약보증금 상당액 지급 확약서를 받음 (시행령 제53조 제2항, 관습에 따른 면제는 생략 가능)
  - 면제 근거 조항을 계약 서류에 적어 둠

  ### ✅ 담당자 체크리스트
  - [ ] 계약금액 5천만원 이하인가, 계약을 나누지 않았는가
  - [ ] 상대방이 시행령 제37조 제3항 해당자인가
  - [ ] 확약서를 받았는가
  - [ ] 면제 근거를 서류에 적고 결재했는가
  MD
  [ :commentary, "## 계약보증금 면제 실무 가이드", <<~'MD' ]
  ## 계약보증금 면제 실무 가이드

  > 2026-09-17 원문 대조로 정정했습니다. 종전 해설의 «3천만원 이하 면제», «상장법인·신용평가 AA 이상 면제», «개산·단가·긴급계약 면제»는 법령 원문에서 확인되지 않았습니다.

  ### 1단계: 금액 확인
  - 계약금액이 **5천만원 이하**이면 면제할 수 있습니다(시행령 제53조 제1항 제2호).
  - 같은 목적의 계약을 나눠 금액 기준을 맞추면 안 됩니다.

  ### 2단계: 상대방 확인
  - 국가기관·다른 지방자치단체, 공기업·준정부기관, 지방공사·지방공단, 국가나 지방자치단체가 기본재산의 100분의 50 이상을 출자·출연한 법인, 농협·수협·산림조합·중소기업협동조합 등 시행령 제37조 제3항 제1호~제5호·제6호의2 해당자와의 계약은 금액과 관계없이 면제할 수 있습니다(제53조 제1항 제1호).

  ### 3단계: 그 밖의 면제 사유
  - 공정·타당한 계약 관습상 계약보증금 징수가 적합하지 않은 경우(제3호)
  - 이미 도입된 외국자본시설·기계·장비의 부분품을 해당 공급자에게서만 살 수 있는 경우(제4호)

  ### 4단계: 면제 후 조치
  - 면제받은 자에게 계약보증금 상당액 지급 확약서를 받습니다. 관습에 따른 면제(제3호)는 생략할 수 있습니다(제53조 제2항).
  - 계약상대자가 계약상 의무를 이행하지 않으면 계약보증금에 해당하는 금액을 내게 해야 합니다(지방계약법 제15조 제3항).

  ### 체크리스트
  - [ ] 계약금액 5천만원 이하 또는 시행령 제37조 제3항 해당자인가
  - [ ] 계약을 나누지 않았는가
  - [ ] 확약서를 받았는가
  - [ ] 면제 근거 조항을 서류에 적었는가
  MD
]

faqs_answers = JSON.parse(<<~'JSON')
  {
   "계약보증금은 얼마이고, 면제가 가능한가요?": "계약보증금은 원칙적으로 내게 해야 합니다(지방계약법 제15조 제1항). 공사계약은 이행보증 방법의 하나로 계약금액의 100분의 10 이상을 낼 수 있습니다(시행령 제51조 제1항 제1호). 계약금액 5천만원 이하 계약이나 국가기관·지방자치단체·공기업 등 시행령 제37조 제3항 해당자와의 계약 등은 면제할 수 있습니다(시행령 제53조 제1항).",
   "계약보증금 대신 다른 방법으로 보증할 수 있나요?": "계약보증금은 현금 또는 시행령 제37조 제2항 각 호의 보증서 등으로 내게 합니다(지방계약법 시행령 제52조). 면제받은 경우에는 계약보증금 상당액 지급 확약서를 받습니다(제53조 제2항)."
  }
JSON

quick_stats_new = JSON.parse(<<~'JSON')
  [
   {
    "note": "지방계약법 제15조 제1항",
    "label": "계약보증금",
    "value": "원칙적으로 납부"
   },
   {
    "note": "시행령 제53조 제1항 제2호",
    "label": "금액 면제",
    "value": "계약금액 5천만원 이하"
   },
   {
    "note": "시행령 제53조 제1항 제1호",
    "label": "상대방 면제",
    "value": "제37조 제3항 해당자(국가기관·지자체·공기업 등)"
   },
   {
    "note": "시행령 제53조 제2항",
    "label": "면제 시",
    "value": "지급 확약서 제출"
   }
  ]
JSON

subs = [
  [ "performance-guarantee", :regulation_content, "| **소액 수의계약** (2천만 원 이하) | 면제 가능 |", "| **계약금액 5천만 원 이하** | 면제 가능 (시행령 제53조 제1항 제2호) |" ],
  [ "performance-guarantee", :rule_content, "- 2천만원 이하: 면제 가능 (재량)", "- 계약금액 5천만원 이하: 면제 가능 (재량, 시행령 제53조 제1항 제2호)" ],
  [ "performance-guarantee", :practical_tips, "<li>· 2천만원 이하: 면제 가능</li>", "<li>· 계약금액 5천만원 이하: 면제 가능 (시행령 제53조)</li>" ],
  [ "performance-guarantee", :faqs, "2천만원 이하 소액 계약은 계약보증금을 면제할 수 있습니다.", "계약금액 5천만원 이하 계약은 계약보증금을 면제할 수 있습니다(지방계약법 시행령 제53조 제1항 제2호)." ],
  [ "performance-guarantee", :faqs, "2천만원 이하 계약도 이행보증서 내야 하나요?", "5천만원 이하 계약도 이행보증서 내야 하나요?" ],
  [ "bid-deposit", :practical_tips, "<li>· 2천만원 이하: 면제 가능</li>", "<li>· 면제: 국가기관·지자체·공기업 등 시행령 제37조 제3항 해당자 (금액 기준 없음)</li>" ],
  [ "bid-deposit", :commentary, "• 소액 입찰: <strong>면제 가능</strong> (기관별 기준, 보통 5천만원 미만)", "• 면제: 시행령 제37조 제3항 해당 입찰참가자 (<strong>금액 기준 없음</strong>)" ],
  [ "bid-deposit", :qa_content, "추정가격 5천만원 미만의 소액 입찰은 면제되는 경우가 있으며, ", "면제는 금액이 아니라 시행령 제37조 제3항의 입찰참가자(국가기관·지방자치단체·공기업 등)에 해당할 때 가능하며, " ],
  [ "bid-deposit", :regulation_content, "- 「국가를 당사자로 하는 계약에 관한 법률」 제12조에 따른 면제 대상 준용\n- 지방자치단체가 입찰 상대방인 경우\n- 「중소기업기본법」상 소기업과의 계약으로 추정가격이 **2천만 원 이하**인 경우\n- 전자입찰로 진행되는 **소액 입찰** (각 발주기관 내규에서 정한 금액 이하)", "- 국가기관·다른 지방자치단체, 공기업·준정부기관, 지방공사·지방공단, 국가·지방자치단체가 기본재산의 100분의 50 이상을 출자·출연한 법인, 농협·수협·산림조합·중소기업협동조합 등 지방계약법 시행령 제37조 제3항 각 호에 해당하는 입찰참가자\n- 입찰금액 기준 면제 규정은 없습니다" ],
  [ "bid-deposit", :faqs, "입찰금액이 2천만원 이하인 경우 입찰보증금을 면제할 수 있습니다. 면제 여부는 발주기관의 재량이므로 입찰공고문을 확인해야 합니다.", "입찰금액 기준 면제 규정은 없습니다. 입찰보증금 면제는 국가기관·지방자치단체·공기업 등 지방계약법 시행령 제37조 제3항에 해당하는 입찰참가자에게 적용하며, 면제 여부는 입찰공고문을 확인하세요." ],
  [ "bid-deposit", :faqs, "2천만원 이하 소액 입찰도 보증금을 내야 하나요?", "소액 입찰도 보증금을 내야 하나요?" ]
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
  topic = Topic.find_by!(slug: "contract-guarantee-exemption")
  field_replacements.each do |column, fingerprint, text|
    current = topic.public_send(column).to_s
    next if current == text
    raise "FIELD_CHANGED_SINCE_AUDIT contract-guarantee-exemption/#{column}" unless current.include?(fingerprint)

    topic.update_columns(column => text, updated_at: Time.current) unless dry_run
    changed += 1
  end

  faqs = Array(topic.faqs)
  new_faqs = faqs.map { |item| faqs_answers.key?(item["question"]) ? item.merge("answer" => faqs_answers[item["question"]]) : item }
  if new_faqs != faqs
    raise "FIELD_CHANGED_SINCE_AUDIT contract-guarantee-exemption/faqs" unless faqs.to_json.include?("3천만원 이하")

    topic.update_columns(faqs: new_faqs, updated_at: Time.current) unless dry_run
    changed += 1
  end

  if topic.quick_stats != quick_stats_new
    raise "FIELD_CHANGED_SINCE_AUDIT contract-guarantee-exemption/quick_stats" unless topic.quick_stats.to_json.include?("소액 계약")

    topic.update_columns(quick_stats: quick_stats_new, updated_at: Time.current) unless dry_run
    changed += 1
  end

  subs.each do |slug, column, from, to|
    record = Topic.find_by!(slug: slug)
    value = record.public_send(column)
    next if contains.call(value, to) && !contains.call(value, from)
    raise "STALE_TEXT_NOT_FOUND #{slug}/#{column}: #{from[0, 40]}" unless contains.call(value, from)

    record.update_columns(column => deep_sub.call(value, from, to), updated_at: Time.current) unless dry_run
    changed += 1
  end

  puts "  [g37-batch3] #{dry_run ? 'DRY_RUN ' : ''}changes=#{changed}"
  raise ActiveRecord::Rollback if dry_run
end
