# frozen_string_literal: true

# 2026-06-18 배치13 — AuditCase legal_basis 조문 라벨 정정(content-fix) 후 attest.
#
# 배치12에서 제외했던 6건: legal_basis의 조문 번호↔제목 라벨이 law.go.kr 정본과 불일치.
# 1차출처(LBOX 법령DB, 2026-06-18) 확정:
#   지방계약법(법률) §7=계약사무의 위임·위탁 / §9①=계약의 방법(일반입찰 원칙) / §15=계약보증금
#   지방계약법 시행령 §13=입찰의 참가자격 / §25=수의계약에 의할 수 있는 경우 / §51=계약의 이행보증 /
#     §53=계약보증금 면제 / §77=공사의 분할계약 금지 / §79=단가계약
# 정정 방향:
#   §7"경쟁의 원칙"(오기, 실제=위임·위탁) → §9①/§9"계약의 방법"(일반경쟁입찰 원칙의 정확한 근거)
#   §13"경쟁입찰에 의한 계약"(오기, 실제=입찰 참가자격) → 제거(법§9①+령§25가 이미 정확 anchor)
#   §51"계약보증금"(오기, 실제=계약의 이행보증) → "계약의 이행보증" 라벨 정정(§51은 이행보증, 보증 미징수에 관련)
# 무결성: 합성 콘텐츠(특정 실사례 아님) — verification_source에 정직 공시(배치6/12 컨벤션 동일).

# slug => [[field, old, new], ...]  (멱등: old 미발견 시 no-op)
FIXES = {
  "split-contract-to-avoid-bidding" => [
    [ :legal_basis, "지방계약법 제7조 제1항 (경쟁의 원칙)", "지방계약법 제9조 제1항 (계약의 방법)" ],
    [ :lesson, "지방계약법 제7조(경쟁 원칙) 위반", "지방계약법 제9조(계약의 방법) 위반" ]
  ],
  "split-order-monthly-to-avoid-bidding" => [
    [ :legal_basis, "지방계약법 제7조 제1항 (경쟁의 원칙)", "지방계약법 제9조 제1항 (계약의 방법)" ]
  ],
  "unit-price-contract-quantity-exceeded" => [
    [ :legal_basis, "지방계약법 제7조 (경쟁의 원칙)", "지방계약법 제9조 (계약의 방법)" ]
  ],
  "small-amount-intentional-split" => [
    [ :legal_basis, "지방계약법 제7조 제1항 (경쟁의 원칙)", "지방계약법 제9조 제1항 (계약의 방법)" ],
    [ :lesson, "지방계약법 제7조는 경쟁 원칙을 규정하며", "지방계약법 제9조는 일반경쟁입찰 원칙을 규정하며" ]
  ],
  "public-procurement-mandatory-bid-bypassed" => [
    [ :legal_basis, "지방계약법 시행령 제13조 (경쟁입찰에 의한 계약), ", "" ]
  ],
  "contract-guarantee-not-collected" => [
    [ :legal_basis, "지방계약법 시행령 제51조 (계약보증금)", "지방계약법 시행령 제51조 (계약의 이행보증)" ]
  ]
}.freeze

# ── Phase 1: content-fix (update! — 콜백/IndexNow 재핑 트리거) ──
fix_log = []
FIXES.each do |slug, edits|
  a = AuditCase.find_by(slug: slug)
  if a.nil?
    fix_log << "#{slug}: NOT_FOUND"; next
  end
  changes = {}
  edits.each do |field, old_s, new_s|
    cur = a.public_send(field).to_s
    if cur.include?(old_s)
      changes[field] = cur.gsub(old_s, new_s)
    end
  end
  if changes.any?
    a.update!(changes)
    fix_log << "#{slug}: fixed [#{changes.keys.join(',')}]"
  else
    fix_log << "#{slug}: no-op(이미 정정됨)"
  end
end
puts "── content-fix ──"
puts fix_log.map { |l| "  #{l}" }

# ── Phase 2: attest (update_columns — 메타만, 배치6/12 패턴) ──
method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 18)

updated = 0
skipped = []
FIXES.each_key do |slug|
  a = AuditCase.find_by(slug: slug)
  next if a.nil?
  lb = a.legal_basis.to_s.strip
  budget = 200 - prefix.length - suffix.length
  lb_fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
  src = "#{prefix}#{lb_fit}#{suffix}"
  if src.length > 200
    skipped << "#{slug}(len#{src.length})"; next
  end
  a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
  updated += 1
end
puts "── attest ──"
puts "✅ E-E-A-T 검증 슬롯 채움 #{updated}/#{FIXES.size}건 (2026-06-18 배치13 — content-fix 후 attest)"
puts "⚠️  길이초과 skip: #{skipped.join(', ')}" if skipped.any?

# ── 잔존 오기 가드 (0이어야) ──
residual = []
FIXES.each_key do |slug|
  a = AuditCase.find_by(slug: slug); next if a.nil?
  lb = a.legal_basis.to_s
  residual << "#{slug}.legal_basis '제7조'" if lb.include?("제7조")
  residual << "#{slug}.legal_basis '제13조 (경쟁입찰'" if lb.include?("제13조 (경쟁입찰")
  residual << "#{slug}.legal_basis '제51조 (계약보증금)'" if lb.include?("제51조 (계약보증금)")
end
puts residual.empty? ? "── 잔존 오기 가드: CLEAN ──" : "⚠️ 잔존: #{residual.join(' | ')}"
