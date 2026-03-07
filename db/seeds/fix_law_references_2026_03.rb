# 법령 오류 수정 스크립트 (2026-03-07)
# 목적: silmu-tool-validator 검증에서 발견된 오류 2건 수정
#   1. 분할계약 금지: 공사 수의계약 기준금액 4,000만원 → 2,000만원
#   2. 유찰 후 수의계약: 제25조 제1항 제6호 → 제26조 제1항
# 참고: find_or_create_by! 패턴은 기존 레코드를 업데이트하지 않으므로 이 스크립트로 별도 수정

puts "=== 법령 오류 수정 시작 ==="

# ===== 1. 분할계약 금지 — 공사 수의계약 기준금액 수정 =====
topic = Topic.find_by(slug: "split-contract")
if topic
  %i[law_content decree_content].each do |field|
    value = topic.read_attribute(field)
    next if value.blank?

    value = value.gsub(
      "2,000만원/물품·용역, 4,000만원/공사",
      "물품·용역·공사 모두 2,000만원"
    )
    value = value.gsub(
      "2천만원(물품·용역), 4천만원(공사) 이하",
      "2,000만원 이하 (물품·용역·공사 공통)"
    )
    value = value.gsub(
      "추정가격 2천만원(물품·용역), 4천만원(공사) 이하",
      "추정가격 2,000만원 이하 (물품·용역·공사 공통)"
    )
    value = value.gsub(
      "공사 수의계약 기준 4,000만원 이하이나 동일 공사로 볼 수 있음",
      "공사 수의계약 기준 2,000만원 초과이며 동일 공사로 분할계약에 해당"
    )
    value = value.gsub(
      "추정가격 **4,000만원 이하**",
      "추정가격 **2,000만원 이하**"
    )
    value = value.gsub(
      "| **공사** | 추정가격 **4,000만원 이하** | 부가세 제외 기준 |",
      "| **공사** | 추정가격 **2,000만원 이하** | 부가세 제외 기준 (물품·용역과 동일) |"
    )
    value = value.gsub(
      "| 수의계약 기준 | 시행령 제25조 | 추정가격 2천만원(물품·용역), 4천만원(공사) 이하 |",
      "| 수의계약 기준 | 시행령 제25조 제1항 제5호 | 추정가격 2,000만원 이하 (물품·용역·공사 공통) |"
    )
    topic.write_attribute(field, value)
  end
  topic.save!
  puts "✅ split-contract 수정 완료"
else
  puts "⚠️  split-contract 토픽을 찾을 수 없음"
end

# ===== 2. 유찰 후 수의계약 — 조항 번호 수정 =====
topic = Topic.find_by(slug: "bid-failure-negotiation")
if topic
  fields = %i[law_content decree_content rule_content regulation_content interpretation_content qa_content]

  fields.each do |field|
    value = topic.read_attribute(field)
    next if value.blank?

    # 제목/헤더 수정
    value = value.gsub(
      "지방계약법 시행령 제25조 제1항 제6호 (유찰 후 수의계약)",
      "지방계약법 시행령 제26조 (재공고입찰과 수의계약)"
    )
    value = value.gsub(
      "**지방계약법 시행령 제25조 제1항 제6호:**",
      "**지방계약법 시행령 제26조 제1항:**"
    )
    value = value.gsub(
      "**지방계약법 시행령 제25조 제1항 제6호 단서:**",
      "**지방계약법 시행령 제26조 제2항:**"
    )
    # 조문 표 수정
    value = value.gsub(
      "시행령 제25조 제1항 제6호 | 유찰 후 수의계약의 기본 요건",
      "시행령 제26조 제1항 | 재공고입찰 유찰 후 수의계약의 기본 요건"
    )
    value = value.gsub(
      "시행령 제25조 제1항 제8호 | 낙찰자가 계약을 체결하지 않은 경우 수의계약",
      "시행령 제26조 제2항 | 1인 입찰 등 재공고 없이 수의계약 가능한 특례"
    )
    value = value.gsub("시행령 제20조 | 재공고 입찰 절차", "시행령 제19조 | 재공고 입찰 절차")
    # 결재서류
    value = value.gsub(
      "시행령 제25조 제1항 제6호 해당 근거",
      "시행령 제26조 제1항 해당 근거"
    )
    # 규정 섹션
    value = value.gsub(
      "즉시 수의계약 가능 (시행령 제25조 제1항 제8호)",
      "차순위자 협의 또는 재공고 실시 (지방자치단체 입찰 및 계약집행기준)"
    )
    # 유권해석 근거
    value = value.gsub(
      "근거: 시행령 제25조 제1항 제6호",
      "근거: 시행령 제26조 제1항"
    )
    # 긴급 요건 번호 수정
    value = value.gsub(
      "시행령 제25조 제1항 제3호",
      "시행령 제25조 제1항 제1호·제2호 (천재지변·재난 긴급복구)"
    )
    topic.write_attribute(field, value)
  end

  # audit_cases 컬럼 (has_many 연관명과 충돌하므로 write_attribute 사용)
  audit_val = topic.read_attribute(:audit_cases)
  if audit_val.present?
    audit_val = audit_val.gsub(
      "지방계약법 시행령 제25조 제1항 제6호 (2회 유찰 원칙)",
      "지방계약법 시행령 제26조 제1항 (재공고입찰과 수의계약)"
    )
    audit_val = audit_val.gsub(
      "시행령 제25조 제1항 제6호",
      "시행령 제26조 제1항"
    )
    topic.write_attribute(:audit_cases, audit_val)
  end

  topic.save!
  puts "✅ bid-failure-negotiation 수정 완료"
else
  puts "⚠️  bid-failure-negotiation 토픽을 찾을 수 없음"
end

puts "=== 법령 오류 수정 완료 ==="
