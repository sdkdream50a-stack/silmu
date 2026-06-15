# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치3 (부존재 조문 §16의2 클러스터 + §90 선급금 오기 + 시행규칙 §47의2 부존재)
# 2026-06-04. legal_basis/본문 전수 grep(폐지·부존재 조문 재검사) 중 적발한 잔존 결함 정정.
# cf. [[project_topic_content_defects_2026_06_03]] (배치1=1a614fb, 배치2=afc283e §42의2/공무국외여행규정).
#
# 검증 근거(korean-law MCP, 2026-06-04, 전수 실측):
#   지방계약법(법, mst253973): §16=감독·§17=검사·§18=대가의 지급. **§16의2 = 부존재(조회 실패)**.
#   지방계약법 시행령(mst286149): §16=물품·용역 입찰·§19=재입찰 및 재공고입찰·§39=입찰서 제출(지정
#     정보처리장치 전자제출)·§67=대가의 지급(5일)·§68=지연이자·§90=지연배상금. **§16의2 = 부존재**.
#   지방회계법(법, mst276363): §35 = 선금급과 개산급.
#   소득세법(법, mst285523): §140 = 근로소득자의 소득공제 등 신고. 소득세법 시행규칙 §47의2 = 부존재.
#   하도급거래 공정화에 관한 법률(법, mst273643): §16의2 = 공급원가 변동 하도급대금 조정 (★실존, 정정 불요).
#
# 🛡️ 정정 매트릭스(부존재/오기 조문만 외과적 교체, HTML·내용 보존):
#   ① payment.law_content/interpretation: "지방계약법 제16조의2 (대가의 지급)"=부존재 → 법 §18.
#      (시행령 §68=지연이자 → 대가지급 기한은 §67) 동반 정정.
#   ② e-bidding.decree/interpretation: "시행령 제16조의2 (전자입찰)"=부존재 → 시행령 §39(입찰서 전자제출).
#   ③ e-bidding-error-faq.regulation: "시행령 제16조의2"=부존재 → 시행령 §39.
#   ④ bid-announcement.decree: "제16조의2 (재공고입찰)"=부존재 → 시행령 §19(재입찰 및 재공고입찰).
#   ⑤ budget-execution.interpretation: "지방계약법 시행령 제90조...선급금"=오기(§90=지연배상금,선금 무관,
#      법 §18①은 「지방회계법」 선금급 근거) → 「지방회계법」 §35(선금급과 개산급)+예규.
#   ⑥ year-end-settlement.rule: "소득세법 시행규칙 제47조의2"=부존재 → 소득세법 §140(근로소득자 소득공제 신고).
# ⛔ 정정 제외(실존 확인): price-escalation 하도급법 §16의2 / late-penalty 시행령 §90(지연배상금) /
#   budget-transfer·budget-compilation 지방재정법 §47의2(이용·이체).
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_03_batch3.rb})"'

fixes = [
  [ "payment", "law_content", [
    [ "지방계약법 제16조의2 (대가의 지급)", "지방계약법 제18조 (대가의 지급)" ]
  ] ],
  [ "payment", "interpretation_content", [
    [ "지방계약법 제16조의2, 시행령 제68조", "지방계약법 제18조, 시행령 제67조" ]
  ] ],
  [ "e-bidding", "decree_content", [
    [ "제16조의2 (전자입찰)", "제39조 (입찰서의 제출·전자입찰)" ]
  ] ],
  [ "e-bidding", "interpretation_content", [
    [ "지방계약법 시행령 제16조의2", "지방계약법 시행령 제39조" ]
  ] ],
  [ "e-bidding-error-faq", "regulation_content", [
    [ "지방계약법 시행령 제16조의2", "지방계약법 시행령 제39조" ]
  ] ],
  [ "bid-announcement", "decree_content", [
    [ "제16조의2 (재공고입찰)", "제19조 (재입찰 및 재공고입찰)" ]
  ] ],
  [ "budget-execution", "interpretation_content", [
    [ "지방계약법 시행령 제90조에 따라 선급금", "「지방회계법」 제35조(선금급과 개산급) 및 관련 예규에 따라 선급금" ]
  ] ],
  [ "year-end-settlement", "rule_content", [
    [ "## 소득세법 시행규칙 관련 조문", "## 소득세법 관련 조문" ],
    [ "소득세법 시행규칙 제47조의2", "소득세법 제140조" ],
    [ "**제47조의2 (소득·세액공제 증명서류)**", "**소득세법 제140조 (근로소득자의 소득·세액 공제 신고)**" ]
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

puts "[content_fix batch3] #{results.join(' | ')}"

# 잔존 결함 검증 (부존재 조문이 0이어야 정상 / 실존 조문은 제외)
puts "--- 잔존 검증 ---"
# §16의2 (지방계약법) — price-escalation의 하도급법 §16의2는 제외
%w[payment e-bidding e-bidding-error-faq bid-announcement].each do |s|
  t = Topic.find_by(slug: s); next unless t
  blob = %w[law_content decree_content regulation_content rule_content qa_content interpretation_content].map { |f| t.public_send(f).to_s }.join("\n")
  n = blob.scan("제16조의2").size
  puts "  #{s}: 지계 제16조의2 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
end
# budget-execution: 시행령 제90조(선급금 문맥) 제거 확인
be = Topic.find_by(slug: "budget-execution")
if be
  n = be.interpretation_content.to_s.scan("시행령 제90조").size
  puts "  budget-execution: interp 시행령 제90조 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
end
# year-end: 시행규칙 §47의2 제거 확인
ye = Topic.find_by(slug: "year-end-settlement")
if ye
  n = ye.rule_content.to_s.scan("제47조의2").size
  puts "  year-end-settlement: rule 제47조의2 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
end
