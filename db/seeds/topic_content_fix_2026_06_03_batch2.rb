# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치2 (폐지 시행령 §42의2 + 부존재 대통령령 인용)
# 2026-06-03. quick_stats 백필(배치8·9) 중 전수 grep으로 적발한 잔존 본문 결함 정정.
# cf. [[project_topic_content_defects_2026_06_03]] (1차 4건은 commit 1a614fb+4ac1e5d로 완료,
#     본 배치는 그 때 누락됐던 필드 + 새로 적발한 §42의2 폐지조문 인용).
#
# 검증 근거(korean-law MCP, 2026-06-03):
#   지방계약법 시행령(mst286149): §42의2 = **삭제(폐지) 실측 확인**. 적격심사(계약이행능력 심사)는
#     현행 §42(재정지출 부담 입찰에서의 낙찰자 결정) §42②로 통합. 전자입찰(입찰서 제출)은 §39①
#     (지정정보처리장치 전자 제출 원칙).
#   "공무국외여행에 관한 규정"(대통령령) = **부존재**(국가공무원법 §73=휴직의 효력). 국외출장 허가는
#     각 기관 「공무국외출장 규정」(훈령·예규)·지자체 조례, 여비는 「공무원 여비 규정」.
#
# 정정 방식: gsub 정밀 치환(HTML·구조 보존). 폐지조문/부존재법령 인용만 외과적 교체.
#   각 치환의 매칭 성공 여부를 출력하고, 마지막에 잔존 결함(제42조의2 / 공무국외여행에 관한 규정) 0 검증.
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_03_batch2.rb})"'

# [slug, field, [[old, new], ...]]
fixes = [
  ["qualification-failure", "law_content", [
    ["## 지방계약법 제13조 (입찰 참가자격 제한 등)", "## 지방계약법 제13조 (낙찰자 결정)"],
    ["법률(제13조) → 시행령(제42조의2) → 집행기준", "법률(제13조) → 시행령(제42조) → 집행기준"]
  ]],
  ["qualification-failure", "decree_content", [
    ["## 지방계약법 시행령 제42조의2 (적격심사)", "## 적격심사 세부 기준 (지방계약법 시행령 제42조 위임 → 「지방자치단체 입찰 및 계약집행기준」)"]
  ]],
  ["e-bidding", "commentary", [
    ["전자입찰은 지방계약법 시행령 제42조의2에 따라 <strong>일정 금액 이상</strong>의 계약은 <strong>의무적으로 전자입찰</strong>로 진행해야 합니다.",
     "전자입찰은 지방계약법 시행령 제39조제1항에 따라 입찰서를 <strong>지정정보처리장치(나라장터)로 전자 제출</strong>하는 것이 원칙이며, 다수 기관이 일정 금액 이상 계약을 전자입찰로 운영합니다."]
  ]],
  ["e-procurement-guide", "commentary", [
    ["나라장터(G2B)와 학교장터(S2B)는 <strong>전자조달시스템</strong>으로, 지방계약법 시행령 제42조의2에 따라 <strong>일정 금액 이상</strong> 계약 시 의무 사용해야 합니다.",
     "나라장터(G2B)와 학교장터(S2B)는 <strong>전자조달시스템</strong>으로, 지방계약법 시행령 제39조제1항(입찰서 전자 제출 원칙) 및 전자조달법에 따라 전자조달을 이용합니다."]
  ]],
  ["lowest-bid-rate", "decree_content", [
    ["다만, 제42조의2에 따른 적격심사를 실시하는 경우에는 그러하지 아니하다.",
     "다만, 제42조제2항에 따른 적격심사(계약이행능력 심사)를 실시하는 경우에는 그러하지 아니하다."]
  ]],
  ["foreign-travel", "decree_content", [
    ["## 공무국외여행에 관한 규정 (대통령령) 주요 조항", "## 공무 국외출장 허가·여비 기준"],
    ["<strong>공무국외여행에 관한 규정 제3조 (국외여행의 허가)</strong>", "<strong>허가권자 (각 기관 「공무국외출장 규정」·조례)</strong>"],
    ["**출장 처리 흐름 (공무국외여행에 관한 규정 기반)**", "**출장 처리 흐름 (기관별 규정 기준)**"],
    ["2. **공무국외여행 신청서 작성** — 소속 기관 양식 (규정 제4조)", "2. **공무국외출장 신청서 작성** — 소속 기관 양식"],
    ["7. **귀국 후 결과보고서 제출** (규정 제12조)", "7. **귀국 후 결과보고서 제출** (소속 기관 규정)"]
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

# faqs (jsonb) — JSON 직렬화 후 부존재 규정명 치환
ft = Topic.find_by(slug: "foreign-travel")
if ft
  json = ft.faqs.to_json
  before = json.scan("공무국외여행에 관한 규정").size
  json = json.gsub("「공무국외여행에 관한 규정」", "「공무국외출장 규정」(기관별 훈령·조례)")
  json = json.gsub("공무국외여행에 관한 규정", "공무국외출장 규정")
  ft.update!(faqs: JSON.parse(json))
  results << "foreign-travel.faqs [replaced #{before}]"
end

puts "[content_fix batch2] #{results.join(' | ')}"

# 잔존 결함 검증
puts "--- 잔존 결함 검증 ---"
%w[qualification-failure e-bidding e-procurement-guide lowest-bid-rate foreign-travel].each do |s|
  t = Topic.find_by(slug: s)
  next unless t
  blob = [t.law_content, t.decree_content, t.regulation_content, t.rule_content, t.commentary, t.qa_content, t.interpretation_content, t.faqs.to_json].map(&:to_s).join("\n")
  a = blob.scan("제42조의2").size
  b = blob.scan("공무국외여행에 관한 규정").size
  flag = (a + b).zero? ? "CLEAN" : "RESIDUAL!!"
  puts "  #{s}: 제42조의2=#{a} 공무국외여행규정=#{b} => #{flag}"
end
