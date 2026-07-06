# frozen_string_literal: true

#
# 계약보증금 면제 한도 오류 재정정
# 2026-07-06.
#
# 배경: 2026-07-06 한시특례 종료 반영 중 계약보증금 "면제 한도"를
# 3천만원 기본 + 5천만원 종료 특례로 잘못 정정한 운영 레코드를 되돌린다.
#
# 확정 기준:
# - 계약보증금 면제: 지방계약법 시행령 제53조 제1항 제2호, 계약금액 5천만원 이하(상시)
# - 계약보증금 세입조치: 시행령 제54조
# - 별개 유지: 계약보증금 요율 10% / 5% 한시 특례 종료
#
# 원칙:
# - slug + field 단위로만 치환한다.
# - old 앵커가 없으면 강제 삽입하지 않고 경고만 출력한다.
# - new가 이미 적용된 경우 no-op으로 처리한다.
# - update_columns로 저장해 IndexNow ping 등 콜백을 피한다.
#
# 운영 적용:
# kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_07_06b_exemption_revert.rb})"'

Fix = Struct.new(:slug, :field, :old, :new, :record_class, keyword_init: true)

FIXES = [
  Fix.new(
    slug: "private-contract",
    field: "qa_content",
    old: "**A**: 계약금액 3천만원 이하인 경우 계약보증금 면제 가능합니다(시행령 제53조). 한시적 특례(5천만원 이하 확대)는 2026.6.30 종료되어, 2026.7.1 이후 공고분은 3천만원 기준입니다(6.30 이전 공고분은 특례 적용).",
    new: "**A**: 계약금액 5천만원 이하인 경우 계약보증금 면제 가능합니다(시행령 제53조). 이 5천만원 기준은 상시 기준이며, 2026.6.30 종료된 보증금 요율 특례와는 별개입니다."
  ),

  Fix.new(
    slug: "small-amount-contract",
    field: "interpretation_content",
    old: "**A:** 추정가격 **3천만원 이하**인 경우 계약보증금 납부를 면제할 수 있습니다(시행령 제53조). ※ 5천만원·공사 1억원 확대는 2026.6.30 종료된 특례(6.30 이전 공고분 적용).",
    new: "**A:** 계약금액 **5천만원 이하**인 경우 계약보증금 납부를 면제할 수 있습니다(시행령 제53조 제1항 제2호). 이 5천만원 기준은 상시 기준이며, 2026.6.30 종료된 보증금 요율 특례와는 별개입니다."
  ),

  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "decree_content",
    old: <<~'OLD'.chomp,
      | **국가·지자체** 등 공공기관과 계약 | 전액 면제 |
      | 추정가격 **3천만원 이하** (물품·용역) | 전액 면제 가능 |
      | 공사 소액·이행보증서 등 원칙 기준 | 면제 또는 대체 가능 여부 판단 |
      | 2026.6.30 이전 공고분 한시 특례 | 물품·용역 5천만원·공사 1억원까지 면제 가능 |
      | **법령에 의한 허가·등록 업체** 중 신용 양호 | 일부 면제 |
    OLD
    new: <<~'NEW'.chomp
      | **국가·지자체** 등 공공기관과 계약 | 전액 면제 |
      | 계약금액 **5천만원 이하** | 전액 면제 가능 |
      | 공사 이행보증서 등 원칙 기준 | 대체 가능 여부 판단 |
      | **법령에 의한 허가·등록 업체** 중 신용 양호 | 일부 면제 |
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "decree_content",
    old: "### 제52조 (계약보증금의 귀속)",
    new: "### 제54조 (계약보증금의 세입조치)"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "rule_content",
    old: <<~'OLD'.chomp,
      ① **면제 판단 기준:**
      - 물품·용역: 추정가격 **3천만원 이하** 시 면제 가능
      - 공사: 소액 또는 이행보증서 제출 등 원칙에 따라 판단
      - 5천만원(물품·용역)·1억원(공사)은 2026.6.30 종료된 특례(6.30 이전 공고분 적용)
      - 면제 시에도 계약불이행 시 **10% 상당액 징수** 가능
    OLD
    new: <<~'NEW'.chomp
      ① **면제 판단 기준:**
      - 계약금액 **5천만원 이하** 시 면제 가능(시행령 제53조 제1항 제2호 상시 기준)
      - 공사 이행보증서 제출 등 원칙에 따라 대체 가능 여부 판단
      - 면제 시에도 계약불이행 시 **10% 상당액 징수** 가능
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "interpretation_content",
    old: "- 근거: 시행령 제52조 제2항",
    new: "- 근거: 시행령 제54조 제2항"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "qa_content",
    old: <<~'OLD'.chomp,
      **A:**
      - **물품·용역:** 추정가격 **3천만원 이하**
      - **공사:** 소액 또는 이행보증서 제출 등 원칙에 따라 판단
      - **종료된 특례:** 2026.6.30 이전 공고분은 물품·용역 5천만원·공사 1억원 기준 적용
      - **공공기관** (국가·지자체·공기업 등)과의 계약
    OLD
    new: <<~'NEW'.chomp
      **A:**
      - **계약금액 5천만원 이하:** 시행령 제53조 제1항 제2호 상시 기준
      - **공사:** 이행보증서 제출 등 원칙에 따라 대체 가능 여부 판단
      - **공공기관** (국가·지자체·공기업 등)과의 계약
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "practical_tips",
    old: "<li>☐ 면제 사유 해당 여부 확인 (현행 3천만원 기준; 5천만원/1억원 특례는 2026.6.30 종료)</li>",
    new: "<li>☐ 면제 사유 해당 여부 확인 (계약금액 5천만원 이하, 시행령 제53조 상시 기준)</li>"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "practical_tips",
    old: "<li><strong>면제 기준 착각:</strong> 현행 물품·용역 3천만원 기준, 5천만원·공사 1억원은 종료된 특례</li>",
    new: "<li><strong>면제 기준 착각:</strong> 계약금액 5천만원 이하가 시행령 제53조의 상시 기준이며, 종료된 보증금 요율 특례와 별개</li>"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "faqs",
    old: "물품·용역은 추정가격 3천만원 이하인 경우 면제가 가능합니다. 공사는 소액 또는 이행보증서 제출 등 원칙에 따라 판단합니다. 5천만원(물품·용역)·1억원(공사) 기준은 2026.6.30 종료된 특례로, 6.30 이전 공고분에 적용됩니다. 다만 면제해도 계약불이행 시 10% 상당액을 징수할 수 있습니다.",
    new: "계약금액 5천만원 이하인 경우 면제가 가능합니다(시행령 제53조 제1항 제2호). 공사는 이행보증서 제출 등 원칙에 따라 대체 가능 여부도 함께 판단합니다. 다만 면제해도 계약불이행 시 10% 상당액을 징수할 수 있습니다."
  ),

  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "keywords",
    old: "계약보증금 면제, 이행보증금 면제, 보증금 면제 기준, 3천만원 이하, 5천만원 특례, 소액 계약 보증금 면제, 보증금 생략",
    new: "계약보증금 면제, 이행보증금 면제, 보증금 면제 기준, 5천만원 이하, 소액 계약 보증금 면제, 보증금 생략"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "summary",
    old: "추정가격 3천만원 이하 물품·용역 계약은 계약보증금 면제 가능 (시행령 기준). 한시적 특례(5천만원 확대)는 2026.6.30 종료(현재 3천만원 기준). 국가기관, 지자체 등 특정 상대방과 계약 시에도 면제",
    new: "계약금액 5천만원 이하 계약은 계약보증금 면제 가능 (시행령 제53조 상시 기준). 국가기관, 지자체 등 특정 상대방과 계약 시에도 면제"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "decree_content",
    old: <<~'OLD'.chomp,
      <strong style="font-size:18px;">✅ 물품·용역 3천만원 이하 = 면제 가능 (기본)</strong>

      추정가격이 **3천만원 이하**인 물품·용역 계약의 경우 계약보증금을 면제할 수 있습니다.
      </div>

      <div style="background:#d1fae5; padding:16px; border-radius:8px; margin-top:8px;">
      <strong style="font-size:16px;">📢 한시적 특례 종료 (2026.6.30 만료)</strong>

      한시적 특례 적용기간(~2026.6.30) 중에는 물품·용역 5천만원·공사 1억원까지 면제가 확대됐으나 종료됐습니다. 2026.7.1 이후 공고분은 기본 기준(3천만원)이며, 6.30 이전 공고분은 공고일 기준으로 특례가 적용됩니다.
    OLD
    new: <<~'NEW'.chomp
      <strong style="font-size:18px;">✅ 계약금액 5천만원 이하 = 면제 가능 (상시)</strong>

      계약금액이 **5천만원 이하**인 계약의 경우 계약보증금을 면제할 수 있습니다. 이는 시행령 제53조 제1항 제2호의 상시 기준입니다.
      </div>

      <div style="background:#d1fae5; padding:16px; border-radius:8px; margin-top:8px;">
      <strong style="font-size:16px;">📢 요율 특례와 구분</strong>

      2026.6.30 종료된 한시 특례는 계약보증금 요율 10%→5% 인하 등입니다. 계약보증금 면제 기준 5천만원은 그 특례가 아니라 시행령 제53조의 상시 기준입니다.
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "rule_content",
    old: <<~'OLD'.chomp,
      #### 1. 소액 계약
      - **물품·용역**: 추정가격 **3천만원** 이하 (현행 기본)
      - **공사**: 특례(1억원) 종료 — 현행 별도 면제 특례 없음
      - 단, 발주기관이 필요 시 보증금 징수 가능
    OLD
    new: <<~'NEW'.chomp
      #### 1. 소액 계약
      - **계약금액 5천만원 이하**: 시행령 제53조 제1항 제2호 상시 기준
      - **공사**: 이행보증서 제출 등 원칙에 따라 대체 가능 여부 판단
      - 단, 발주기관이 필요 시 보증금 징수 가능
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "**Q: 추정가격이 면제 기준 이하인가?**",
    new: "**Q: 계약금액이 면제 기준 이하인가?**"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: <<~'OLD'.chomp,
      - **기본 기준**: 물품·용역 **3천만원** 이하
      - **한시적 특례(2026.6.30 종료)**: 특례기간 중 물품·용역 5천만원·공사 1억원까지였음(현재 3천만원)
    OLD
    new: <<~'NEW'.chomp
      - **상시 기준**: 계약금액 **5천만원** 이하(시행령 제53조 제1항 제2호)
      - **주의**: 2026.6.30 종료된 한시 특례는 보증금 요율 인하 등으로, 면제 5천만원 기준과 별개
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: <<~'OLD'.chomp,
      - 물품 추정가격 2,500만원 → 면제 가능 (기본 기준)
      - 물품 추정가격 4,800만원 → 2026.6.30 이전 공고분만 면제 가능(특례 종료)
      - 2026.7.1 이후 공고분은 3천만원 초과 시 면제 불가
    OLD
    new: <<~'NEW'.chomp
      - 계약금액 2,500만원 → 면제 가능
      - 계약금액 4,800만원 → 면제 가능(시행령 제53조 상시 기준)
      - 계약금액 5,500만원 → 금액 기준으로는 면제 불가
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- 일반 민간 기업 (3천만원 초과 물품·용역 계약)",
    new: "- 일반 민간 기업 (5천만원 초과 계약)"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- 면제 기준 금액(3천만원; 5천만원 특례는 2026.6.30 종료) 초과 계약에서 보증금 면제",
    new: "- 면제 기준 금액(계약금액 5천만원) 초과 계약에서 보증금 면제"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- [ ] 추정가격이 면제 기준(3천만원) 이하인가? (5천만원 특례는 2026.6.30 종료)",
    new: "- [ ] 계약금액이 면제 기준(5천만원) 이하인가? (시행령 제53조 상시 기준)"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "A: 기본 기준은 물품·용역 **3천만원** 이하입니다. 한시적 특례(5천만원 확대)는 2026.6.30 종료되어, 2026.7.1 이후 공고분은 3천만원 기준입니다. \"면제 가능\"이지 \"필수 면제\"가 아니므로 발주기관이 계약상대자의 신용도, 이행 능력 등을 고려하여 판단합니다.",
    new: "A: 계약금액 **5천만원** 이하입니다. 이 기준은 시행령 제53조 제1항 제2호의 상시 기준이며, 2026.6.30 종료된 보증금 요율 특례와 별개입니다. \"면제 가능\"이지 \"필수 면제\"가 아니므로 발주기관이 계약상대자의 신용도, 이행 능력 등을 고려하여 판단합니다."
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "A: 네, 가능합니다. 3천만원 이하 계약이므로 면제할 수 있습니다. 다만, 신규 업체이거나 신용도가 불확실하면 보증금을 징수하는 것이 안전합니다.",
    new: "A: 네, 가능합니다. 5천만원 이하 계약이므로 면제할 수 있습니다. 다만, 신규 업체이거나 신용도가 불확실하면 보증금을 징수하는 것이 안전합니다."
  ),

  Fix.new(
    slug: "contract-guarantee-exemption-wrong",
    field: "checkpoints",
    old: "현행 물품·용역 3천만원 면제 기준금액 확인 (5천만원·공사 1억원은 2026.6.30 종료된 특례)",
    new: "계약금액 5천만원 이하 면제 기준 확인 (시행령 제53조 상시 기준)",
    record_class: AuditCase
  ),
  Fix.new(
    slug: "contract-no-guarantee-forfeiture",
    field: "legal_basis",
    old: "지방계약법 시행령 제52조",
    new: "지방계약법 시행령 제54조",
    record_class: AuditCase
  )
].freeze

def value_include?(value, needle)
  case value
  when String
    value.include?(needle)
  when Array
    value.any? { |item| value_include?(item, needle) }
  when Hash
    value.any? { |key, item| value_include?(key, needle) || value_include?(item, needle) }
  else
    false
  end
end

def occurrence_count(value, needle)
  case value
  when String
    value.scan(needle).size
  when Array
    value.sum { |item| occurrence_count(item, needle) }
  when Hash
    value.sum { |key, item| occurrence_count(key, needle) + occurrence_count(item, needle) }
  else
    0
  end
end

def replace_value(value, old_s, new_s)
  case value
  when String
    value.gsub(old_s, new_s)
  when Array
    value.map { |item| replace_value(item, old_s, new_s) }
  when Hash
    value.transform_keys { |key| replace_value(key, old_s, new_s) }
         .transform_values { |item| replace_value(item, old_s, new_s) }
  else
    value
  end
end

fixed_pairs = 0
fixed_occurrences = 0
already_applied = 0
missing = 0
not_found = 0
updated_fields = []

FIXES.group_by { |fix| [fix.record_class || Topic, fix.slug, fix.field] }.each do |(record_class, slug, field), fixes|
  record = record_class.find_by(slug: slug)
  label = "#{record_class.name} #{slug}.#{field}"

  if record.nil?
    not_found += fixes.size
    puts "WARN #{label}: NOT_FOUND"
    next
  end

  unless record.respond_to?(field)
    missing += fixes.size
    puts "WARN #{label}: field NOT_FOUND"
    next
  end

  original_value = record.public_send(field)
  value = original_value

  fixes.each do |fix|
    count = occurrence_count(value, fix.old)

    if count.positive?
      value = replace_value(value, fix.old, fix.new)
      fixed_pairs += 1
      fixed_occurrences += count
    elsif value_include?(value, fix.new)
      already_applied += 1
    else
      missing += 1
      puts "WARN #{label}: old anchor missing; skipped"
    end
  end

  next if value == original_value

  record.update_columns(field => value)
  updated_fields << label
end

residuals = []
FIXES.group_by { |fix| [fix.record_class || Topic, fix.slug, fix.field] }.each do |(record_class, slug, field), fixes|
  record = record_class.find_by(slug: slug)
  next unless record&.respond_to?(field)

  value = record.public_send(field)
  count = fixes.sum { |fix| occurrence_count(value, fix.old) }
  residuals << "#{record_class.name} #{slug}.#{field}=#{count}" if count.positive?
end

puts "계약보증금 면제 한도 재정정 결과:"
puts "  FIXED pairs: #{fixed_pairs} (occurrences: #{fixed_occurrences})"
puts "  UPDATED fields: #{updated_fields.size}#{updated_fields.any? ? " (#{updated_fields.join(', ')})" : ''}"
puts "  ALREADY applied pairs: #{already_applied}"
puts "  MISSING old anchors: #{missing}"
puts "  NOT_FOUND pairs: #{not_found}"
puts "  RESIDUAL old anchors: #{residuals.empty? ? '0 — CLEAN' : residuals.join(', ')}"
