# frozen_string_literal: true
#
# 토픽 본문 법령결함 정정 — 배치5 (배치4 누락 필드 보강 / 운영 DB 인라인 사후 정정의 committed 재현 시드)
# 2026-06-04. cf. [[project_topic_content_defects_2026_06_03]] (배치1 1a614fb·배치2 afc283e·배치3 ba59a8b·배치4 dccabc9).
#
# 경위: 배치4의 초기 스캔이 Topic 콘텐츠필드를 정규식 /legal|content/ 로 필터해 commentary·interpretation_content
#   등 일부 텍스트컬럼을 누락 → 부존재 조문 3건이 잔존. 배치4 배포 직후 운영 DB에 kamal runner로 직접 update!
#   (인라인) 정정했으나 committed 시드가 없어 재현성·이미지 시드디렉 완전성 결손 → 본 배치5로 문서화.
#   ⚠️ 운영 DB는 이미 인라인 적용 완료(잔존0 검증). 본 시드를 현행 운영 DB에 재실행하면 전부 MISS(=정상,
#   멱등). 시드 원본(과거 결함 상태)이 복원될 경우의 자기치유·정정 이력 보존 목적.
#
# 검증 근거(korean-law MCP, 2026-06-04 실측):
#   건설산업기본법(법) §29 = 건설공사 하도급 제한, §29③ = 불법 재하도급(다시 하도급) 금지.
#     하도급법(하도급거래 공정화에 관한 법률) §14의2 = **부존재**(§14 하도급대금 직접지급은 실존).
#   초중등교육법 시행령 §64 = 학교발전기금. §65의2 = **부존재**.
#   지방계약법 시행령 §90 = 지연배상금(지체상금)·§90③ = 한도 30%. §74의2 = **부존재**(§74 설계변경 조정은 실존).
#
# 🛡️ 정정 매트릭스(부존재 조문번호 → 실존 조문):
#   subcontract.commentary:                 하도급법 제14조의2(부존재)      → 건설산업기본법 제29조제3항(재하도급 금지)
#   school-budget-compilation.interpretation: 초중등교육법 시행령 제65조의2(부존재) → 초중등교육법 시행령 제64조(학교발전기금)
#   penalty-reduction-procedure.commentary:  지방계약법 시행령 제74조의2(부존재) → 지방계약법 시행령 제90조(지연배상금) ×2
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch5.rb})"'

fixes = [
  ["subcontract", "commentary", [
    ["하도급법 제14조의2", "건설산업기본법 제29조제3항"]
  ]],
  ["school-budget-compilation", "interpretation_content", [
    ["초중등교육법 시행령 제65조의2", "초중등교육법 시행령 제64조"]
  ]],
  ["penalty-reduction-procedure", "commentary", [
    ["지방계약법 시행령 제74조의2", "지방계약법 시행령 제90조"]
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
      matched << "MISS" # 인라인 기적용 상태에서는 MISS가 정상
    end
  end
  topic.update!(field => content)
  results << "#{slug}.#{field} [#{matched.join(',')}]"
end

puts "[content_fix batch5] #{results.join(' | ')}"

# 잔존 부존재 조문 검증 (해당 토픽/필드 한정)
puts "--- 잔존 검증 ---"
checks = {
  "subcontract"                 => { commentary: "제14조의2" },
  "school-budget-compilation"   => { interpretation_content: "제65조의2" },
  "penalty-reduction-procedure" => { commentary: "제74조의2" }
}
checks.each do |slug, fmap|
  t = Topic.find_by(slug: slug); next unless t
  fmap.each do |f, pat|
    n = t.public_send(f).to_s.scan(pat).size
    puts "  #{slug}.#{f} '#{pat}' 잔존=#{n} => #{n.zero? ? 'CLEAN' : 'RESIDUAL!!'}"
  end
end
