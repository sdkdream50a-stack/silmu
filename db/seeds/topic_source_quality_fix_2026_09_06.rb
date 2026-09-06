# frozen_string_literal: true

#
# 원천 품질 정정 — 계약서 작성(§14/§49/§50) · 입찰공고 시기(§35)
# 2026-09-06. cf. topic_content_fix_2026_06_15_bid_period_v2.rb (동일 패턴).
#
# 배경: command_center 가 두 건의 원천 결함을 지목했다(CPSC-P3D-001 · CPEB-P3C-001).
#   법제처 정본 재대조 결과, 지목 내용의 일부는 사실이 아니었고 **반대 방향의 결함**이 실재했다.
#
# 정본(law.go.kr 2026-09-06 실측):
#   지방계약법 [시행 2024. 2. 17.] [법률 제19634호]
#     §14① 기재사항 = 목적·계약금액·이행기간·계약보증금·위험부담·**지연배상금(遲延賠償金)**, 단서 = 작성 생략 위임
#     §14② = **전자문서에 의한 계약서 작성 의무**(천재지변 등 예외)   ← 생략 위임 조항이 아니다
#     §14③ = 기명·날인/서명(전자서명 포함)으로 계약 확정
#   지방계약법 시행령 [시행 2026. 6. 3.] [대통령령 제36338호]
#     §49 = 계약서 **서식**을 행정안전부령에 위임(기재사항 조문이 아니다)
#     §50① = 생략 5개 호(5천만원 이하 / 경매 / 물품매각 즉시대금 / 국가기관·다른 지자체 / 공급계약 등)
#            → **금액 기준은 계약 종류 불문 5천만원 단일. "공사 1억원"은 부존재.**
#     §50② = §14② 전자계약 예외의 정의
#     §35③ = 공사입찰 현장설명 미실시: 10억 미만 7 / 10~50억 15 / **50억~고시금액 30** / 고시금액 이상 40
#     §35⑤ = 규격·기술입찰, 협상에 의한 계약: **1억 미만 10** / 1억~10억 20 / 10억 이상 40
#
# 정정 대상(잘못이 실재한 것만):
#   contract-execution : law(§14② 오기재) · decree(§49 기재사항 오귀속 · §50 "공사 1억" 부존재·2개 호 누락) ·
#                        summary(위험부담 누락) · verification_source(§49 기재·지체상금·공사 1억)
#   bid-announcement   : summary(50억 이상 40일 = 30일 구간 누락) · howto 3단계("1억 이상 10일" = §35⑤ 역전)
#   bidding            : howto 2단계(50억 이상 40일)
#   bid-announcement   : quick_stats(50억 이상 40일)
#
# ⛔ 정정하지 않은 것(정본 대조 결과 **원래 옳았다**):
#   · summary 의 "지연배상금"  — §14① 정본 용어. 지방계약법은 지체상금이 아니라 지연배상금이다.
#   · summary 의 "전자문서로 작성하는 것이 원칙" — §14② 그 자체.
#   · quick_stats 의 "전자계약 원칙 / 지방계약법 제14조제2항(천재지변 등 예외)" — 정확한 인용.
#
# 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_source_quality_fix_2026_09_06.rb})"'
# 멱등: 이미 정정된 경우 old 미존재 → MISS(no-op).
#

# ── 1. 텍스트 필드 정정 ──────────────────────────────────────
law14_old = <<~OLD.strip
  ① 지방자치단체의 장 또는 계약담당자는 계약을 체결하려면 계약의 목적·계약금액·이행기간 등 **대통령령으로 정하는 사항을 명백히 기재한 계약서**를 작성하여야 한다.

  ② 다만, 대통령령으로 정하는 경우에는 계약서 작성을 **생략**할 수 있다.
OLD

law14_new = <<~NEW.strip
  ① 지방자치단체의 장 또는 계약담당자는 계약을 체결하려는 경우에는 계약의 **목적·계약금액·이행기간·계약보증금·위험부담·지연배상금(遲延賠償金)**, 그 밖에 필요한 사항을 명백히 적은 계약서를 작성하여야 한다. **다만, 대통령령으로 정하는 경우에는 계약서의 작성을 생략할 수 있다.**

  ② 지방자치단체의 장 또는 계약담당자는 계약을 체결하려는 경우에는 **천재지변 등 대통령령으로 정하는 경우를 제외하고는** 행정안전부장관이 지정하는 정보처리장치를 이용하여 「전자서명법」에 따른 **전자문서에 의한 계약서**를 작성하여야 한다.

  ③ 제1항 본문에 따라 계약서를 작성하는 경우에는 계약담당자와 계약상대자가 계약서에 **기명·날인하거나 서명(전자서명 포함)**함으로써 계약이 확정된다.
NEW

decree49_old = <<~OLD.strip
  ### 제49조 (계약서의 작성)

  계약서에 기재해야 할 사항:
  1. 계약의 **목적**
  2. **계약금액**
  3. **이행기간**
  4. 계약보증금
  5. 위험부담
  6. 지체상금
  7. 계약불이행 시 조치사항
  8. 기타 필요한 사항
OLD

decree49_new = <<~NEW.strip
  ### 제49조 (계약서의 작성)

  법 제14조제1항에 따라 계약담당자가 작성하는 **계약서의 서식과 그 밖에 필요한 사항은 행정안전부령**으로 정한다.

  > ⚠️ 계약서 **기재사항 자체는 법 제14조제1항**이 직접 정한다 — 목적·계약금액·이행기간·계약보증금·**위험부담**·**지연배상금**, 그 밖에 필요한 사항. 시행령 제49조는 서식 위임 조항이다.
NEW

decree50_old = <<~OLD.strip
  ### 제50조 (계약서 작성 생략)

  다음 경우 계약서 작성 생략 가능:
  - 계약금액 **5천만원 이하** (물품·용역)
  - 계약금액 **1억원 이하** (공사)
  - 전기·가스·수도 등의 공급계약
  - 경매에 부치는 경우
OLD

decree50_new = <<~NEW.strip
  ### 제50조 (계약서 작성의 생략 등)

  ① 법 제14조제1항 **단서**에 따라 계약서 작성을 생략할 수 있는 경우:
  1. 계약금액이 **5천만원 이하**인 계약을 체결하는 경우 *(공사·물품·용역을 구분하지 않는 단일 기준)*
  2. **경매**에 부치는 경우
  3. 물품을 매각할 때 **매수인이 즉시 대금을 내고** 그 물품을 인수하는 경우
  4. **국가기관**과 계약을 체결하거나 **다른 지방자치단체**와 계약을 체결하는 경우
  5. 전기·가스·수도의 **공급계약** 등 그 계약의 성질상 계약서를 작성할 필요가 없는 경우

  ② 법 제14조제2항의 "천재지변 등 대통령령으로 정하는 경우"란 **천재지변·전산장애 또는 그 밖의 부득이한 사유로 정보처리장치를 이용할 수 없는 경우**를 말한다.
NEW

text_fixes = [
  [ "contract-execution", "law_content", [
    [ "## 지방계약법 제14조 (계약서의 작성)", "## 지방계약법 제14조 (계약서의 작성 및 계약의 성립)" ],
    [ law14_old, law14_new ],
    [ "- **원칙:** 모든 계약은 계약서를 작성하여 체결 (제14조 제1항)",
      "- **원칙:** 모든 계약은 계약서를 작성하여 체결 (제14조 제1항 **본문**)" ],
    [ "- **예외:** 계약금액 5천만원 이하 등 일정 요건 시 계약서 생략 가능 (시행령 제50조)",
      "- **예외:** 계약금액 5천만원 이하 등 일정 요건 시 계약서 생략 가능 (제14조 제1항 **단서** → 시행령 제50조 제1항)\n" \
      "- **전자계약 원칙:** 천재지변·전산장애 등 부득이한 사유를 제외하고 전자문서로 작성 (제14조 **제2항** → 시행령 제50조 제2항)" ]
  ] ],
  [ "contract-execution", "decree_content", [
    [ decree49_old, decree49_new ],
    [ decree50_old, decree50_new ]
  ] ],
  [ "contract-execution", "summary", [
    [ "목적·금액·이행기간·계약보증금·지연배상금을 필수 기재",
      "목적·금액·이행기간·계약보증금·위험부담·지연배상금을 필수 기재" ],
    [ "(계약금액 5천만원 이하는 계약서 생략 가능)", "(계약금액 5천만원 이하 등은 계약서 생략 가능)" ]
  ] ],
  [ "bid-announcement", "summary", [
    [ "입찰공고는 추정가격 10억 미만 7일·10~50억 15일·50억 이상 40일 이상 게시해야 하며, 긴급입찰은 사유 명시 시 5일입니다.",
      "입찰공고는 원칙 7일 이상이며, 공사입찰(현장설명 미실시)은 추정가격 10억 미만 7일·10~50억 15일·50억~고시금액 30일·고시금액 이상 40일입니다. 재공고·긴급은 5일." ]
  ] ]
]

results = []
text_fixes.each do |slug, field, pairs|
  topic = Topic.find_by(slug: slug)
  if topic.nil?
    results << "#{slug}.#{field} NOT_FOUND"
    next
  end
  before = topic.public_send(field).to_s
  content = before.dup
  matched = pairs.map do |old_s, new_s|
    if content.include?(old_s)
      content = content.gsub(old_s, new_s)
      "OK"
    else
      "MISS"
    end
  end
  topic.update!(field => content) if content != before
  results << "#{slug}.#{field} [#{matched.join(',')}]#{content == before ? ' (no-op)' : ' (updated)'}"
end

# ── 2. verification_source (varchar(200)) ────────────────────
VERIF_NEW = "법제처 — 지방계약법 §14①(기재: 목적·금액·이행기간·계약보증금·위험부담·지연배상금)·§14②(전자문서 원칙)·§14③(성립), 시행령 §49(서식 위임)·§50①(생략: 5천만원 이하 등 5개 호)·§50②(전자계약 예외). 운영(silmu.kr) 정본 일치 확인"
abort "❌ verification_source 200자 초과: #{VERIF_NEW.length}" if VERIF_NEW.length > 200

ce = Topic.find_by(slug: "contract-execution")
if ce
  ce.update_columns(
    verification_source: VERIF_NEW,
    verification_method: "law.go.kr 1:1 대조 (법률 제19634호·대통령령 제36338호 조문 원문 재대조)",
    last_verified_at: Date.new(2026, 9, 6)
  )
  results << "contract-execution.verification_source (updated)"
end

# ── 3. jsonb 배열(howto_steps · quick_stats) 항목 내 문자열 정정 ──
JSON_FIXES = [
  [ "bid-announcement", :howto_steps,
    "일반 7일 이상, 추정가격 1억 이상 시 10일 이상, 긴급 시 5일 이상. 공휴일 산입 여부 확인.",
    "원칙 7일 이상(시행령 §35①). 공사입찰 현장설명 미실시는 10억 미만 7일·10~50억 15일·50억~고시금액 30일·고시금액 이상 40일(§35③). 규격·기술입찰과 협상에 의한 계약은 1억 미만 10일·1억~10억 20일·10억 이상 40일(§35⑤). 재공고·긴급은 5일 이상(§35④). 공휴일 산입 여부 확인." ],
  [ "bidding", :howto_steps,
    "추정가격별 최소 공고기간을 확인한다(10억 미만 7일·10억~50억 15일·50억 이상 40일, 긴급 5일 이상). 미준수 시 입찰 무효.",
    "추정가격별 최소 공고기간을 확인한다(공사·현장설명 미실시 기준 10억 미만 7일·10억~50억 15일·50억~고시금액 30일·고시금액 이상 40일, 재공고·긴급 5일 이상). 미준수 시 입찰 무효." ]
]

JSON_FIXES.each do |slug, field, old_s, new_s|
  t = Topic.find_by(slug: slug)
  if t.nil?
    results << "#{slug}.#{field} NOT_FOUND"
    next
  end
  steps = t.public_send(field)
  unless steps.is_a?(Array)
    results << "#{slug}.#{field} NOT_ARRAY"
    next
  end
  hit = false
  new_steps = steps.map do |st|
    s = st.dup
    if s["text"].to_s.include?(old_s)
      s["text"] = s["text"].gsub(old_s, new_s)
      hit = true
    end
    s
  end
  t.update!(field => new_steps) if hit
  results << "#{slug}.#{field} [#{hit ? 'OK' : 'MISS'}]#{hit ? ' (updated)' : ' (no-op)'}"
end

ba = Topic.find_by(slug: "bid-announcement")
if ba && ba.quick_stats.is_a?(Array)
  hit = false
  qs = ba.quick_stats.map do |row|
    r = row.dup
    if r["label"].to_s == "공고기간(50억 이상)" && r["value"].to_s.start_with?("40일")
      r["label"] = "공고기간(50억~고시금액)"
      r["value"] = "30일 이상"
      r["note"]  = "고시금액 이상은 40일"
      hit = true
    elsif r["label"].to_s == "공고기간(10억 미만)" && r["note"].to_s == "추정가격 기준"
      r["note"] = "공사·현장설명 미실시"
      hit = true
    end
    r
  end
  ba.update!(quick_stats: qs) if hit
  results << "bid-announcement.quick_stats [#{hit ? 'OK' : 'MISS'}]#{hit ? ' (updated)' : ' (no-op)'}"
end

puts "[source_quality_fix 2026-09-06] #{results.join(' | ')}"

# ── 4. 양성/음성 읽기검증 ────────────────────────────────────
puts "--- 검증(정정 반영 + 옛 문구 부재 + 원래 옳던 표현 보존) ---"
ok = true

ce = Topic.find_by(slug: "contract-execution")
if ce
  law = ce.law_content.to_s
  dec = ce.decree_content.to_s
  sum = ce.summary.to_s
  checks = {
    "법§14② 전자문서 조항으로 기재"      => law.include?("전자문서에 의한 계약서"),
    "법§14② 옛 '생략' 오기재 제거"        => !law.include?("② 다만, 대통령령으로 정하는 경우에는 계약서 작성을 **생략**할 수 있다"),
    "시행령§49 서식 위임으로 기재"        => dec.include?("행정안전부령"),
    "시행령§49 기재사항 오귀속 제거"      => !dec.include?("계약서에 기재해야 할 사항:"),
    "시행령§50 '공사 1억' 제거"           => !dec.include?("계약금액 **1억원 이하** (공사)"),
    "시행령§50 누락 2개 호 복원"          => dec.include?("매수인이 즉시 대금을 내고") && dec.include?("국가기관"),
    "요약 위험부담 포함"                  => sum.include?("위험부담"),
    "요약 '지연배상금' 보존(정본 용어)"   => sum.include?("지연배상금"),
    "요약 '전자문서 원칙' 보존(§14②)"     => sum.include?("전자문서로 작성하는 것이 원칙"),
    "본문에 '지체상금' 오용 없음"         => !law.include?("지체상금") && !dec.include?("지체상금")
  }
  checks.each { |k, v| ok &&= v; puts "  contract-execution #{k}=#{v ? 'O' : 'X'}" }
end

ba = Topic.find_by(slug: "bid-announcement")
if ba
  sum = ba.summary.to_s
  hs  = ba.howto_steps.to_a.map { |s| s["text"].to_s }.join("\n")
  checks = {
    "요약 30일 구간 복원"        => sum.include?("50억~고시금액 30일"),
    "요약 옛 '50억 이상 40일' 제거" => !sum.include?("50억 이상 40일"),
    "howto §35⑤ 방향 정정"       => hs.include?("1억 미만 10일"),
    "howto 옛 '1억 이상 10일' 제거" => !hs.include?("1억 이상 시 10일")
  }
  checks.each { |k, v| ok &&= v; puts "  bid-announcement #{k}=#{v ? 'O' : 'X'}" }
end

bd = Topic.find_by(slug: "bidding")
if bd
  hs = bd.howto_steps.to_a.map { |s| s["text"].to_s }.join("\n")
  v = hs.include?("50억~고시금액 30일") && !hs.include?("50억 이상 40일")
  ok &&= v
  puts "  bidding howto 30일 구간 복원=#{v ? 'O' : 'X'}"
end

puts ok ? "✅ 원천 정정 반영 확인" : "⚠️ 검증 실패 — 확인 필요"
