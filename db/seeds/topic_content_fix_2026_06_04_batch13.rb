# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치13 (제N조 의미오기 감사 #8: 선금 REFRAME — 가공 조문 제거)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 경위: payment·advance-payment가 계약 선금(선급금)을 **존재하지 않는 조문**에 귀속.
#   "지방계약법 제17조(선금 지급) ①②③"=가공 법조문 전문(실제 §17=검사) / "시행령 제53조(선금의 지급)"
#   (§53=계약보증금 면제) / "시행령 제63~65조(선금)"(§63=주민참여감독자교육·§64=검사·§65=검사조서생략) /
#   "시행규칙 제56~58조" → 전부 가공/오기. 단순 번호교체 불가 → REFRAME.
#
# 정본(법제처 OPEN API 2026-06-04):
#   계약 선금(선급금)의 실질 근거 = **「지방자치단체 입찰 및 계약집행기준」(행정안전부 예규, ID 2100000280194)**
#     — 선금률(공사·물품·용역 70% 이내 등)·선금보증·사용제한·정산.
#   회계법적 근거 = **지방회계법 제35조(선금급과 개산급)**(실측: 운임·용선료·여비, 그 밖에 대통령령으로
#     정하는 경비를 선금급/개산급으로 지급 가능). 지방계약법 시행령에는 선금 조문 없음(개산계약 §81~86뿐).
#   ※실질 수치(70%·사용제한·정산·보증)는 예규상 정확 → 내용 보존, 귀속만 정정.
#   payment 동반: §16=감독→검사는 §17(off-by-one, batch6서 선금충돌로 제외분) / commentary 지연이자는 시행령§68(§65=검사조서생략 오기).
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch13.rb})"'

PYE = "「지방자치단체 입찰 및 계약집행기준」"

fixes = [
  # ── payment ─────────────────────────────────────────────
  ["payment", "law_content", [
    ["## 지방계약법 제17조 (선금 지급)", "## 선금 지급 (지방회계법 제35조·#{PYE})"],
    ["**대통령령으로 정하는 바에 따라 선금을 지급**", "**#{PYE}에 따라 선금을 지급**"],
    ["선금의 사용·정산 등에 필요한 사항은 **대통령령으로 정한다.**", "선금의 사용·정산 등에 필요한 사항은 **#{PYE}(행정안전부 예규)으로 정한다.**"],
    ["선금률, 지급 절차, 정산 방법 등 세부사항은 시행령에 위임", "선금률, 지급 절차, 정산 방법 등 세부사항은 #{PYE}(행정안전부 예규)에 규정"],
    ["선금·기성금·준공금 지급 절차, 지연이자율 등 세부사항은 시행령에 위임", "기성금·준공금 지급 절차·지연이자율 등 세부사항은 시행령에, 선금은 #{PYE}에 위임"],
    ["- **제16조 (검사):**", "- **제17조 (검사):**"]
  ]],
  ["payment", "decree_content", [
    ["### 제53조 (선금의 지급)", "### 선금의 지급 (#{PYE})"]
  ]],
  ["payment", "interpretation_content", [
    ["근거: 지방계약법 제17조 제2항, 시행령 제53조", "근거: #{PYE}(선금 사용·정산)·지방회계법 제35조"]
  ]],
  ["payment", "commentary", [
    ["를 가산하여 지급해야 합니다 (지방계약법 시행령 제65조)", "를 가산하여 지급해야 합니다 (지방계약법 시행령 제68조)"]
  ]],
  # ── advance-payment ─────────────────────────────────────
  ["advance-payment", "law_content", [
    ["## 지방계약법 제17조 (선금)", "## 선금 (지방회계법 제35조·#{PYE})"],
    ["**지방계약법 제17조 (선금)**", "**선금 (지방회계법 제35조·#{PYE})**"],
    ["② 선금의 지급 비율·방법 및 정산 등에 필요한 사항은 대통령령으로 정한다.", "② 선금의 지급 비율·방법 및 정산 등에 필요한 사항은 #{PYE}(행정안전부 예규)으로 정한다."],
    ["구체적인 지급 비율·방법·정산은 시행령에 위임합니다.", "구체적인 지급 비율·방법·정산은 #{PYE}(행정안전부 예규)에 규정되어 있습니다."],
    ["지방계약법 시행령 제63조~제65조, 시행규칙 제56조~제58조", "지방회계법 제35조·#{PYE}(행정안전부 예규)"]
  ]],
  ["advance-payment", "decree_content", [
    ["지방계약법 시행령 제63조~제65조 (선금 지급 기준)", "#{PYE} (선금 지급 기준)"],
    ["**지방계약법 시행령 제63조 (선금 지급 비율)**", "**선금 지급 비율 (#{PYE})**"],
    ["**지방계약법 시행령 제64조 (선금 사용 제한)**", "**선금 사용 제한 (#{PYE})**"],
    ["**지방계약법 시행령 제65조 (선금 정산)**", "**선금 정산 (#{PYE})**"]
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
puts "[content_fix batch13] #{results.join(' | ')}"

# 잔존 검증: 가공/오기 조문 귀속 잔존 0
puts "--- 잔존 검증 (선금 가공조문) ---"
checks = {
  "payment" => {
    law_content: ["지방계약법 제17조 (선금", "대통령령으로 정한다", "세부사항은 시행령에 위임", "제16조 (검사)"],
    decree_content: ["제53조 (선금의 지급)"],
    interpretation_content: ["지방계약법 제17조 제2항"],
    commentary: ["시행령 제65조)"]
  },
  "advance-payment" => {
    law_content: ["지방계약법 제17조 (선금)", "시행령 제63조~제65조, 시행규칙 제56조~제58조"],
    decree_content: ["시행령 제63조 (선금", "시행령 제64조 (선금", "시행령 제65조 (선금"]
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
# 정정 근거 출현 확인
puts "--- 정정 근거 출현 ---"
%w[payment advance-payment].each do |slug|
  t = Topic.find_by(slug: slug); next unless t
  allc = %i[law_content decree_content interpretation_content commentary].map{|f| t.public_send(f).to_s}.join
  puts "  #{slug}: 집행기준=#{allc.scan('입찰 및 계약집행기준').size} 지방회계법제35조=#{allc.scan('지방회계법 제35조').size}"
end
