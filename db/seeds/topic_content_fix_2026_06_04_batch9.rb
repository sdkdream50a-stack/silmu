# frozen_string_literal: true

#
# 토픽 본문 법령결함 정정 — 배치9 (제N조 의미오기 감사 #4: 입찰공고·입찰절차 조문번호)
# 2026-06-04. cf. [[project_cite_meaning_audit_2026_06_04]].
#
# 정본(법제처 OPEN API 2026-06-04):
#   지방계약법 본법(253973): §9=계약의 방법·§9의2=구매규격 사전공개·§10=입찰공고·§13=낙찰자 결정.
#   시행령(286149): §12=입찰의 성립·§13=입찰의 참가자격·§14=입찰참가자격 사전심사·§15=공사의 입찰·
#     §16=물품의 제조구매용역 입찰·§18=2단계 입찰·§19=재입찰 및 재공고입찰·§20=제한입찰·§22=지명입찰·
#     §33=입찰공고·§35=입찰공고의 시기·§39=입찰서의 제출접수 및 입찰의 무효·§42=재정지출부담입찰 낙찰자결정.
#
# 결함: bidding·bid-announcement가 입찰절차 조문번호 다수 오인용. §9의2(=구매규격공개)를 입찰무효로,
#   §10(=입찰공고)을 입찰성립으로, 시행령 §14(=사전심사)를 제한경쟁·§15(=공사입찰)를 지명경쟁·
#   §16(=물품입찰)을 입찰공고·§18(=2단계)을 입찰성립유찰·§20(=제한입찰)을 낙찰자결정으로.
#
# 🛡️ 정정 매트릭스:
#   bidding.law_content(본법 관련조항): "제9조의2 (입찰 무효)"→"시행령 제39조 (입찰의 무효)" /
#     "제10조 (입찰의 성립)"→"시행령 제12조 (입찰의 성립)"  (§9 계약방법·§13 낙찰자결정=정확, 무수정)
#   bidding.decree_content(시행령): §14(제한경쟁입찰)→§20 / §15(지명경쟁입찰)→§22 / §16(입찰공고)→§33 /
#     §18(입찰의 성립과 유찰)→§12 / §20(낙찰자 결정)→§42  (§13 일반경쟁 참가자격=정확, 무수정)
#   bid-announcement.law_content(본법): "제9조의2 (입찰의 무효)"→"시행령 제39조 (입찰의 무효)" /
#     "제10조 (입찰의 성립)"→"시행령 제12조 (입찰의 성립)"  (§9=정확)
#   bid-announcement.decree_content: "시행령 제16조 (입찰공고)"→"시행령 제33조 (입찰공고)"  (§19 재입찰=정확)
#
# 운영 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_04_batch9.rb})"'

fixes = [
  [ "bidding", "law_content", [
    [ "제9조의2 (입찰 무효)", "시행령 제39조 (입찰의 무효)" ],
    [ "제10조 (입찰의 성립)", "시행령 제12조 (입찰의 성립)" ]
  ] ],
  [ "bidding", "decree_content", [
    [ "### 제20조 (낙찰자 결정)", "### 제42조 (낙찰자 결정)" ],
    [ "### 제14조 (제한경쟁입찰)", "### 제20조 (제한경쟁입찰)" ],
    [ "### 제15조 (지명경쟁입찰)", "### 제22조 (지명경쟁입찰)" ],
    [ "### 제16조 (입찰공고)", "### 제33조 (입찰공고)" ],
    [ "### 제18조 (입찰의 성립과 유찰)", "### 제12조 (입찰의 성립과 유찰)" ]
  ] ],
  [ "bid-announcement", "law_content", [
    [ "제9조의2 (입찰의 무효)", "시행령 제39조 (입찰의 무효)" ],
    [ "제10조 (입찰의 성립)", "시행령 제12조 (입찰의 성립)" ]
  ] ],
  [ "bid-announcement", "decree_content", [
    [ "시행령 제16조 (입찰공고)", "시행령 제33조 (입찰공고)" ]
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
puts "[content_fix batch9] #{results.join(' | ')}"

puts "--- 잔존 검증 ---"
checks = {
  "bidding" => {
    law_content: [ "제9조의2 (입찰 무효)", "제10조 (입찰의 성립)" ],
    decree_content: [ "### 제14조 (제한경쟁입찰)", "### 제15조 (지명경쟁입찰)", "### 제16조 (입찰공고)", "### 제18조 (입찰의 성립과 유찰)", "### 제20조 (낙찰자 결정)" ]
  },
  "bid-announcement" => {
    law_content: [ "제9조의2 (입찰의 무효)", "제10조 (입찰의 성립)" ],
    decree_content: [ "시행령 제16조 (입찰공고)" ]
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
