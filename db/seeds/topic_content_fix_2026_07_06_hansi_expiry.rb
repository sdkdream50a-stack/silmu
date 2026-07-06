# frozen_string_literal: true

#
# 토픽 본문 한시적 특례 종료 반영
# 2026-07-06. cf. commit 627242a
#
# 배경: db/seeds의 Topic.find_or_create_by! 블록은 기존 운영 DB 레코드를 갱신하지 않으므로,
# 운영 라이브 레코드에만 외과적으로 old -> new 본문 치환을 적용한다.
#
# 원칙:
# - slug + field 단위로만 치환한다.
# - old 앵커가 없으면 강제 삽입하지 않고 경고만 출력한다.
# - new가 이미 적용된 경우 no-op으로 처리한다.
# - update_columns로 저장해 IndexNow ping 등 콜백을 피한다.
#
# 운영 적용:
# kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb})"'

Fix = Struct.new(:slug, :field, :old, :new, :record_class, keyword_init: true)

FIXES = [
  Fix.new(
    slug: "private-contract-amount",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-1">
            <li>• 한시적 특례 적용 여부는 <strong>공고일(견적요청일) 기준</strong>으로 판단</li>
            <li>• 특례 기간 내 공고했다면, 계약 체결이 기간 이후라도 특례 적용</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-1">
            <li>• 한시적 특례 적용 여부는 <strong>공고일(견적요청일) 기준</strong>으로 판단</li>
            <li>• 6.30 이전 공고했다면, 계약 체결이 7월 이후라도 특례 적용(공고일 기준)</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),

  Fix.new(
    slug: "bidding",
    field: "decree_content",
    old: "- ※ 한시적 특례(~2026.6.30): 1인 입찰 시 재공고 없이 바로 수의계약 가능",
    new: "- ※ 한시적 특례(1인 입찰 시 재공고 없이 바로 수의계약)는 2026.6.30 종료 — 2026.7.1 이후 공고분부터 재공고입찰 후에만 1인 수의계약 가능(시행령 제25조 제1항 제5호)"
  ),
  Fix.new(
    slug: "bidding",
    field: "qa_content",
    old: "- ※ 한시적 특례(~2026.6.30): 1인 입찰 시 재공고 없이 바로 수의계약 가능",
    new: "- ※ 한시적 특례(1인 입찰 시 재공고 없이 바로 수의계약)는 2026.6.30 종료 — 2026.7.1 이후 공고분부터 재공고입찰 후에만 1인 수의계약 가능(시행령 제25조 제1항 제5호)"
  ),
  Fix.new(
    slug: "bidding",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>1인 입찰 수의계약:</strong> 재공고 없이 <strong>바로 수의계약</strong> 가능</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>1인 입찰 수의계약 특례:</strong> 특례기간(~2026.6.30)에는 재공고 없이 바로 가능했으나 <strong>종료</strong> — 현재는 재공고입찰 후에만 가능</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),
  Fix.new(
    slug: "bidding",
    field: "faqs",
    old: "1인만 참가하거나 입찰 성립요건을 충족하지 못하면 유찰됩니다. 유찰 시 재공고입찰을 실시하며, 재공고에도 1인만 참가하면 그 1인과 수의계약이 가능합니다(시행령 제25조 제1항 제5호). 참고로 한시적 특례(~2026.6.30) 기간에는 1인 입찰 시 재공고 없이 바로 수의계약이 가능합니다.",
    new: "1인만 참가하거나 입찰 성립요건을 충족하지 못하면 유찰됩니다. 유찰 시 재공고입찰을 실시하며, 재공고에도 1인만 참가하면 그 1인과 수의계약이 가능합니다(시행령 제25조 제1항 제5호). 참고로 한시적 특례(1인 입찰 시 재공고 없이 바로 수의계약)는 2026.6.30자로 종료되어, 2026.7.1 이후 공고분부터는 재공고입찰 후에만 1인 수의계약이 가능합니다."
  ),

  Fix.new(
    slug: "restricted-bidding",
    field: "qa_content",
    old: "- ※ 한시적 특례(~2026.6.30): 1인 입찰 시 재공고 없이 바로 수의계약 가능",
    new: "- ※ 한시적 특례(1인 입찰 시 재공고 없이 바로 수의계약)는 2026.6.30 종료 — 2026.7.1 이후 공고분부터 재공고입찰 후에만 1인 수의계약 가능(시행령 제25조 제1항 제5호)"
  ),
  Fix.new(
    slug: "restricted-bidding",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>1인 입찰 수의계약:</strong> 재공고 없이 <strong>바로 수의계약</strong> 가능 (제한경쟁 포함)</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>1인 입찰 수의계약 특례:</strong> 특례기간(~2026.6.30)에는 재공고 없이 바로 가능했으나 <strong>종료</strong> — 현재는 재공고입찰 후에만 가능(제한경쟁 포함)</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),
  Fix.new(
    slug: "restricted-bidding",
    field: "faqs",
    old: "네, 유찰 처리됩니다. 행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 및 지방계약법 시행령 제19조(재입찰 및 재공고입찰)에 따라 입찰자가 2인 이상이어야 입찰이 성립합니다. 유찰 후 재공고입찰을 실시하며, 재공고에도 1인만 참가하면 그 1인과 수의계약이 가능합니다(시행령 제25조 제1항 제5호). 한시적 특례(~2026.6.30) 기간에는 1인 입찰 시 재공고 없이 바로 수의계약이 가능합니다.",
    new: "네, 유찰 처리됩니다. 행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 및 지방계약법 시행령 제19조(재입찰 및 재공고입찰)에 따라 입찰자가 2인 이상이어야 입찰이 성립합니다. 유찰 후 재공고입찰을 실시하며, 재공고에도 1인만 참가하면 그 1인과 수의계약이 가능합니다(시행령 제25조 제1항 제5호). 한시적 특례(1인 입찰 시 재공고 없이 바로 수의계약)는 2026.6.30자로 종료되어, 2026.7.1 이후 공고분부터는 재공고입찰 후에만 1인 수의계약이 가능합니다."
  ),

  Fix.new(
    slug: "payment",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>대금지급 기한:</strong> 5일 → <strong>3일</strong> 이내로 단축</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>대금지급 기한 특례:</strong> 특례기간(~2026.6.30)에는 5일→3일 단축이었으나 <strong>종료</strong> — 현재 5일 이내</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),
  Fix.new(
    slug: "payment",
    field: "practical_tips",
    old: "<li><strong>지급 기한 초과:</strong> 5일 이내(한시적 특례 시 3일) 미지급 시 지연이자 발생 — 기한 관리 철저</li>",
    new: "<li><strong>지급 기한 초과:</strong> 5일 이내(특례 3일 단축은 2026.6.30 종료) 미지급 시 지연이자 발생 — 기한 관리 철저</li>"
  ),

  Fix.new(
    slug: "inspection",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>검사기간:</strong> 14일 → <strong>7일</strong> 이내로 단축</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>검사기간 특례:</strong> 특례기간(~2026.6.30)에는 14일→7일 단축이었으나 <strong>종료</strong> — 현재 14일 이내</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),
  Fix.new(
    slug: "inspection",
    field: "practical_tips",
    old: "<li><strong>검사 기한 초과:</strong> 14일 이내(한시적 특례 시 7일) 미완료 시 지연이자 발생 가능</li>",
    new: "<li><strong>검사 기한 초과:</strong> 14일 이내(특례 7일 단축은 2026.6.30 종료) 미완료 시 지연이자 발생 가능</li>"
  ),

  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "decree_content",
    old: <<~'OLD'.chomp,
      | **국가·지자체** 등 공공기관과 계약 | 전액 면제 |
      | 추정가격 **5천만원 이하** (물품·용역) | 전액 면제 가능 |
      | 추정가격 **1억원 이하** (공사) | 전액 면제 가능 |
      | **법령에 의한 허가·등록 업체** 중 신용 양호 | 일부 면제 |
    OLD
    new: <<~'NEW'.chomp
      | **국가·지자체** 등 공공기관과 계약 | 전액 면제 |
      | 추정가격 **3천만원 이하** (물품·용역) | 전액 면제 가능 |
      | 공사 소액·이행보증서 등 원칙 기준 | 면제 또는 대체 가능 여부 판단 |
      | 2026.6.30 이전 공고분 한시 특례 | 물품·용역 5천만원·공사 1억원까지 면제 가능 |
      | **법령에 의한 허가·등록 업체** 중 신용 양호 | 일부 면제 |
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "rule_content",
    old: <<~'OLD'.chomp,
      ① **면제 판단 기준:**
      - 물품·용역: 추정가격 **5천만원 이하** 시 면제 가능
      - 공사: 추정가격 **1억원 이하** 시 면제 가능
      - 면제 시에도 계약불이행 시 **10% 상당액 징수** 가능
    OLD
    new: <<~'NEW'.chomp
      ① **면제 판단 기준:**
      - 물품·용역: 추정가격 **3천만원 이하** 시 면제 가능
      - 공사: 소액 또는 이행보증서 제출 등 원칙에 따라 판단
      - 5천만원(물품·용역)·1억원(공사)은 2026.6.30 종료된 특례(6.30 이전 공고분 적용)
      - 면제 시에도 계약불이행 시 **10% 상당액 징수** 가능
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "qa_content",
    old: <<~'OLD'.chomp,
      **A:**
      - **물품·용역:** 추정가격 **5천만원 이하**
      - **공사:** 추정가격 **1억원 이하**
      - **공공기관** (국가·지자체·공기업 등)과의 계약
    OLD
    new: <<~'NEW'.chomp
      **A:**
      - **물품·용역:** 추정가격 **3천만원 이하**
      - **공사:** 소액 또는 이행보증서 제출 등 원칙에 따라 판단
      - **종료된 특례:** 2026.6.30 이전 공고분은 물품·용역 5천만원·공사 1억원 기준 적용
      - **공공기관** (국가·지자체·공기업 등)과의 계약
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "practical_tips",
    old: "<li>☐ 면제 사유 해당 여부 확인 (5천만원/1억원 기준)</li>",
    new: "<li>☐ 면제 사유 해당 여부 확인 (현행 3천만원 기준; 5천만원/1억원 특례는 2026.6.30 종료)</li>"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "practical_tips",
    old: <<~'OLD'.chomp,
      한시적 특례 적용 중 (~2026.6.30)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>입찰보증금:</strong> 5% → <strong>2.5%</strong> 이상 (50% 인하)</li>
            <li><strong>계약보증금:</strong> 10% → <strong>5%</strong> 이상 (50% 인하)</li>
            <li><strong>공사이행보증서:</strong> 40% → <strong>20%</strong> 이상 (50% 인하)</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30)</li>
    OLD
    new: <<~'NEW'.chomp
      한시적 특례 종료 (2026.6.30 만료)
          </h4>
          <ul class="text-purple-700 text-sm space-y-2 mt-2">
            <li><strong>입찰보증금:</strong> 특례기간(~2026.6.30) 2.5% 이상이었으나 종료 — 현재 <strong>5%</strong> 이상</li>
            <li><strong>계약보증금:</strong> 특례기간(~2026.6.30) 5% 이상이었으나 종료 — 현재 <strong>10%</strong> 이상</li>
            <li><strong>공사이행보증서:</strong> 특례기간(~2026.6.30) 20% 이상이었으나 종료 — 현재 <strong>40%</strong> 이상</li>
            <li class="text-xs text-purple-500">※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준</li>
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "practical_tips",
    old: "<li><strong>면제 기준 착각:</strong> 물품·용역 5천만원, 공사 1억원 — 기준이 다름</li>",
    new: "<li><strong>면제 기준 착각:</strong> 현행 물품·용역 3천만원 기준, 5천만원·공사 1억원은 종료된 특례</li>"
  ),
  Fix.new(
    slug: "contract-guarantee-deposit",
    field: "faqs",
    old: "물품·용역은 추정가격 5천만원 이하, 공사는 1억원 이하인 경우 면제가 가능합니다. 다만 면제해도 계약불이행 시 10% 상당액을 징수할 수 있습니다.",
    new: "물품·용역은 추정가격 3천만원 이하인 경우 면제가 가능합니다. 공사는 소액 또는 이행보증서 제출 등 원칙에 따라 판단합니다. 5천만원(물품·용역)·1억원(공사) 기준은 2026.6.30 종료된 특례로, 6.30 이전 공고분에 적용됩니다. 다만 면제해도 계약불이행 시 10% 상당액을 징수할 수 있습니다."
  ),

  Fix.new(
    slug: "private-contract",
    field: "qa_content",
    old: "**A**: 계약금액 3천만원 이하인 경우 계약보증금 면제 가능합니다(시행령 제53조). 다만, 한시적 특례(~2026.6.30.)로 5천만원 이하까지 면제가 적용되고 있으므로 최신 기준을 확인하세요.",
    new: "**A**: 계약금액 3천만원 이하인 경우 계약보증금 면제 가능합니다(시행령 제53조). 한시적 특례(5천만원 이하 확대)는 2026.6.30 종료되어, 2026.7.1 이후 공고분은 3천만원 기준입니다(6.30 이전 공고분은 특례 적용)."
  ),
  Fix.new(
    slug: "private-contract",
    field: "qa_content",
    old: "**A**: 계약금액 5천만원 이하인 경우 계약보증금 면제 가능합니다.",
    new: "**A**: 계약금액 3천만원 이하인 경우 계약보증금 면제 가능합니다(시행령 제53조). ※ 5천만원 이하 확대는 2026.6.30 종료된 특례(6.30 이전 공고분 적용)."
  ),

  Fix.new(
    slug: "small-amount-contract",
    field: "interpretation_content",
    old: "**A:** 추정가격 **5천만원 이하**(공사 1억원 이하)인 경우 계약보증금 납부를 면제할 수 있습니다.",
    new: "**A:** 추정가격 **3천만원 이하**인 경우 계약보증금 납부를 면제할 수 있습니다(시행령 제53조). ※ 5천만원·공사 1억원 확대는 2026.6.30 종료된 특례(6.30 이전 공고분 적용)."
  ),

  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "summary",
    old: "추정가격 3천만원 이하 물품·용역 계약은 계약보증금 면제 가능 (시행령 기준). 한시적 특례(~2026.6.30.)로 5천만원 이하까지 면제 확대 적용 중. 국가기관, 지자체 등 특정 상대방과 계약 시에도 면제",
    new: "추정가격 3천만원 이하 물품·용역 계약은 계약보증금 면제 가능 (시행령 기준). 한시적 특례(5천만원 확대)는 2026.6.30 종료(현재 3천만원 기준). 국가기관, 지자체 등 특정 상대방과 계약 시에도 면제"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "decree_content",
    old: "| **공사 (소액)** | **면제 가능** (1억원 이하) |",
    new: "| **공사 (소액)** | 소액·이행보증서 등 원칙 기준 |"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "decree_content",
    old: <<~'OLD'.chomp,
      <strong style="font-size:16px;">📢 한시적 특례 (~2026.6.30.)</strong>

      한시적 특례 적용 기간 중에는 **물품·용역 5천만원 이하**, **공사 1억원 이하**까지 면제 기준이 확대 적용됩니다. 특례 만료 후에는 기본 기준(3천만원)으로 환원되므로 최신 기준을 반드시 확인하세요.
    OLD
    new: <<~'NEW'.chomp
      <strong style="font-size:16px;">📢 한시적 특례 종료 (2026.6.30 만료)</strong>

      한시적 특례 적용기간(~2026.6.30) 중에는 물품·용역 5천만원·공사 1억원까지 면제가 확대됐으나 종료됐습니다. 2026.7.1 이후 공고분은 기본 기준(3천만원)이며, 6.30 이전 공고분은 공고일 기준으로 특례가 적용됩니다.
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "rule_content",
    old: <<~'OLD'.chomp,
      #### 1. 소액 계약
      - **물품·용역**: 추정가격 **3천만원** 이하 (기본) / **5천만원** 이하 (한시적 특례 ~2026.6.30.)
      - **공사**: 추정가격 **1억원** 이하 (한시적 특례 적용 시)
      - 단, 발주기관이 필요 시 보증금 징수 가능
    OLD
    new: <<~'NEW'.chomp
      #### 1. 소액 계약
      - **물품·용역**: 추정가격 **3천만원** 이하 (현행 기본)
      - **공사**: 특례(1억원) 종료 — 현행 별도 면제 특례 없음
      - 단, 발주기관이 필요 시 보증금 징수 가능
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- **한시적 특례(~2026.6.30.)**: 물품·용역 **5천만원** 이하, 공사 **1억원** 이하",
    new: "- **한시적 특례(2026.6.30 종료)**: 특례기간 중 물품·용역 5천만원·공사 1억원까지였음(현재 3천만원)"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: <<~'OLD'.chomp,
      - 물품 추정가격 4,800만원 → 면제 가능 (한시적 특례 적용 시)
      - 특례 만료 후에는 3천만원 초과 시 면제 불가
    OLD
    new: <<~'NEW'.chomp
      - 물품 추정가격 4,800만원 → 2026.6.30 이전 공고분만 면제 가능(특례 종료)
      - 2026.7.1 이후 공고분은 3천만원 초과 시 면제 불가
    NEW
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- 일반 민간 기업 (5천만원 초과 물품·용역 계약)",
    new: "- 일반 민간 기업 (3천만원 초과 물품·용역 계약)"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- 면제 기준 금액(기본 3천만원, 특례 적용 시 5천만원) 초과 계약에서 보증금 면제",
    new: "- 면제 기준 금액(3천만원; 5천만원 특례는 2026.6.30 종료) 초과 계약에서 보증금 면제"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "- [ ] 추정가격이 면제 기준 이하인가? (기본 3천만원, 한시적 특례 5천만원)",
    new: "- [ ] 추정가격이 면제 기준(3천만원) 이하인가? (5천만원 특례는 2026.6.30 종료)"
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "A: 기본 기준은 물품·용역 **3천만원** 이하입니다. 다만 한시적 특례(~2026.6.30.)로 **5천만원** 이하까지 면제가 확대 적용 중입니다. \"면제 가능\"이지 \"필수 면제\"가 아니므로 발주기관이 계약상대자의 신용도, 이행 능력 등을 고려하여 판단합니다.",
    new: "A: 기본 기준은 물품·용역 **3천만원** 이하입니다. 한시적 특례(5천만원 확대)는 2026.6.30 종료되어, 2026.7.1 이후 공고분은 3천만원 기준입니다. \"면제 가능\"이지 \"필수 면제\"가 아니므로 발주기관이 계약상대자의 신용도, 이행 능력 등을 고려하여 판단합니다."
  ),
  Fix.new(
    slug: "contract-guarantee-exemption",
    field: "commentary",
    old: "A: 네, 가능합니다. 5천만원 이하 계약이므로 면제할 수 있습니다. 다만, 신규 업체이거나 신용도가 불확실하면 보증금을 징수하는 것이 안전합니다.",
    new: "A: 네, 가능합니다. 3천만원 이하 계약이므로 면제할 수 있습니다. 다만, 신규 업체이거나 신용도가 불확실하면 보증금을 징수하는 것이 안전합니다."
  ),

  Fix.new(
    slug: "contract-guarantee-exemption-wrong",
    field: "checkpoints",
    old: "물품·용역 5천만원, 공사 1억원 면제 기준금액 확인",
    new: "현행 물품·용역 3천만원 면제 기준금액 확인 (5천만원·공사 1억원은 2026.6.30 종료된 특례)",
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

puts "한시적 특례 종료 본문 정정 결과:"
puts "  FIXED pairs: #{fixed_pairs} (occurrences: #{fixed_occurrences})"
puts "  UPDATED fields: #{updated_fields.size}#{updated_fields.any? ? " (#{updated_fields.join(', ')})" : ''}"
puts "  ALREADY applied pairs: #{already_applied}"
puts "  MISSING old anchors: #{missing}"
puts "  NOT_FOUND pairs: #{not_found}"
puts "  RESIDUAL old anchors: #{residuals.empty? ? '0 — CLEAN' : residuals.join(', ')}"
