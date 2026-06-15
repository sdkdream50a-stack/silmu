# frozen_string_literal: true

#
# 토픽 본문 법령정정 v2 — 입찰공고 시기(§35③) 50억~고시금액 30일 구간 복원
# 2026-06-15. cf. PR #58, topic_content_fix_2026_06_15_bid_period.rb (v1).
#
# 배경(divergence): 프로덕션 토픽 행이 git seed와 갈라져 있었음. v1(원본 2단계 기준)은 prod에서
#   전부 MISS. prod 실조회 결과 bidding·bid-announcement는 이미 3단계(10억미만7·10~50억15·50억이상40)
#   였으나, §35③ 정본은 50억 이상이 둘로 갈림: 50억~고시금액 30일 / 고시금액 이상 40일.
#   즉 prod에 30일 구간이 누락(50억 이상을 40일로 단일화한 부정확). 본 파일이 prod 실문자열을
#   타깃해 30일 구간을 복원.
#
# 정본(law.go.kr + LBOX 이중검증, §35③): 10억미만 7 / 10~50억 15 / 50억~고시금액 30 / 고시금액↑ 40.
#
# 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_06_15_bid_period_v2.rb})"'
# 멱등: 이미 30일 구간이 있으면 old 미존재 → MISS(no-op).

decree_row_old = "| 50억원 이상 | **40일** 이상 |"
decree_row_new = "| 50억원 이상 고시금액 미만 | **30일** 이상 |\n| 고시금액 이상 (국제입찰) | **40일** 이상 |"

tips_row_old = %(          <tr><td class="py-1">50억 이상</td><td>40일+</td><td>20일+</td></tr>\n)
tips_row_new =
  %(          <tr><td class="py-1">50억~고시금액</td><td>30일+</td><td>15일+</td></tr>\n) +
  %(          <tr><td class="py-1">고시금액 이상</td><td>40일+</td><td>20일+</td></tr>\n)

fixes = [
  [ "bidding", "decree_content", [ [ decree_row_old, decree_row_new ] ] ],
  [ "bid-announcement", "decree_content", [ [ decree_row_old, decree_row_new ] ] ],
  [ "bid-announcement", "practical_tips", [ [ tips_row_old, tips_row_new ] ] ]
]

results = []
fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"; next
  end
  before = topic.public_send(field).to_s
  content = before.dup
  matched = []
  pairs.each do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s); matched << "OK"
    else
      matched << "MISS"
    end
  end
  topic.update!(field => content) if content != before
  results << "#{slug}.#{field} [#{matched.join(',')}]#{content == before ? ' (no-op)' : ' (updated)'}"
end
puts "[content_fix bid_period v2] #{results.join(' | ')}"

# ── 양성/음성 읽기검증 (정정 후 실제 상태 확인) ───────────────
puts "--- 검증(정본 구간 존재 + 옛 단일행 부재) ---"
ok = true
[ "bidding", "bid-announcement" ].each do |slug|
  t = Topic.find_by(slug: slug); next unless t
  d = t.decree_content.to_s
  has30 = d.include?("50억원 이상 고시금액 미만 | **30일**")
  old_gone = !d.include?("| 50억원 이상 | **40일** 이상 |")
  ok &&= (has30 && old_gone)
  puts "  #{slug}.decree 30일구간=#{has30 ? 'O' : 'X'} 옛40일단일행제거=#{old_gone ? 'O' : 'X'}"
end
ba = Topic.find_by(slug: "bid-announcement")
if ba
  pt = ba.practical_tips.to_s
  tips_ok = pt.include?("50억~고시금액") && !pt.include?(%(>50억 이상</td><td>40일+))
  ok &&= tips_ok
  puts "  bid-announcement.practical_tips 30일행추가=#{pt.include?('50억~고시금액') ? 'O' : 'X'}"
end
puts ok ? "✅ 정본 4단계(7/15/30/40) 반영 확인" : "⚠️ 검증 실패 — 확인 필요"
