# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치6 (제N조 의미오기 전수감사 #1: 지방계약법 본법 검사·대가 off-by-one)
# 2026-06-04. cf. [[project_topic_content_defects_2026_06_03]] (배치1~5는 부존재/오기 조문).
#
# 경위: "제N조(설명)" 인용 356건을 법제처 API 정본(지방계약법 본법/시행령/시행규칙·지방재정법·지방회계법
#   조문제목 전수)과 귀속기반 대조 → 51토픽 ~167건의 조문번호 의미오기 적발. 본 배치6은 그 중
#   **가장 명확한 off-by-one 클러스터**(지방계약법 본법 검사/대가 조문번호가 한 칸씩 밀림)만 정정.
#
# 정본(법제처 OPEN API 2026-06-04, MST=253973 지방계약법 본법):
#   제16조 = 감독 / 제17조 = 검사 / 제18조 = 대가의 지급 / 제19조 = 대가의 선납.
#   → 토픽들이 검사를 §16, 대가지급을 §17로 인용(한 칸 밀림). batch1(1a614fb)이
#     completion-payment-checklist만 §17검사/§18대가로 기정정, 잔여 토픽에 동일 오기 잔존.
#
# 🛡️ 정정 매트릭스(번호만 교체, 본문·설명·서식 보존):
#   "제16조 (검사)"        → "제17조 (검사)"        [§16=감독이므로 검사는 §17]
#   "제17조 (대가의 지급)" → "제18조 (대가의 지급)" [§17=검사이므로 대가지급은 §18]
#   inspection.commentary "지방계약법 제16조에 따라"(검사 문맥) → "지방계약법 제17조에 따라"
# ⛔ 본 배치 제외(별도 배치): payment(§17 선금지급 = §17검사와 충돌, 선금 재프레이밍 필요)·
#   subcontract(§18 하도급의 승인 = §18대가지급과 충돌, 건산법 재프레이밍 필요)·
#   advance-payment(§17 선금)·입찰보증금/계약보증금/입찰공고/예산(지방재정법) 군 → 후속 배치.
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch6.rb})"'

fixes = [
  ["inspection", "law_content", [
    ["## 지방계약법 제16조 (검사)", "## 지방계약법 제17조 (검사)"],
    ["- **제17조 (대가의 지급):**", "- **제18조 (대가의 지급):**"]
  ]],
  ["inspection", "commentary", [
    ["지방계약법 제16조에 따라", "지방계약법 제17조에 따라"]
  ]],
  ["defect-warranty", "law_content", [
    ["- **제16조 (검사):**", "- **제17조 (검사):**"],
    ["- **제17조 (대가의 지급):**", "- **제18조 (대가의 지급):**"]
  ]],
  ["late-penalty", "law_content", [
    ["- **제16조 (검사):**", "- **제17조 (검사):**"],
    ["- **제17조 (대가의 지급):**", "- **제18조 (대가의 지급):**"]
  ]],
  ["price-escalation", "law_content", [
    ["- **제17조 (대가의 지급):**", "- **제18조 (대가의 지급):**"]
  ]]
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

puts "[content_fix batch6] #{results.join(' | ')}"

# 잔존 검증: 정정 대상 토픽에 "제16조 (검사)"·"제17조 (대가의 지급)" 잔존 0 확인
puts "--- 잔존 검증 (해당 토픽/필드) ---"
checks = {
  "inspection"       => { law_content: ["제16조 (검사)", "제17조 (대가의 지급)"], commentary: ["제16조에 따라"] },
  "defect-warranty"  => { law_content: ["제16조 (검사)", "제17조 (대가의 지급)"] },
  "late-penalty"     => { law_content: ["제16조 (검사)", "제17조 (대가의 지급)"] },
  "price-escalation" => { law_content: ["제17조 (대가의 지급)"] }
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
