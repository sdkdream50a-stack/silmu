# 토픽 관련 대형 상수를 TopicsController에서 분리한 concern
module TopicConfig
  extend ActiveSupport::Concern

  # 토픽별 관련 도구 매핑 (slug → 도구 목록)
  # 각 도구: { path_name:, icon:, title:, desc:, color: }
  TOPIC_TOOLS = {
    "private-contract"        => [ :contract_method, :contract_documents, :contract_reason, :quote_review ],
    "private-contract-limit"  => [ :contract_method, :contract_reason ],
    "private-contract-amount" => [ :contract_method, :estimated_price ],
    "private-contract-overview" => [ :contract_method, :contract_documents, :contract_reason ],
    "single-quote"            => [ :contract_method, :contract_documents, :quote_review, :contract_reason ],
    "dual-quote"              => [ :contract_method, :contract_documents, :quote_review ],
    "emergency-contract"      => [ :contract_method, :contract_documents, :contract_reason ],
    "price-negotiation"       => [ :contract_method, :cost_estimate, :contract_documents ],
    "bidding"                 => [ :contract_method, :estimated_price, :legal_period, :quote_review ],
    "bid-announcement"        => [ :estimated_price, :legal_period ],
    "e-bidding"               => [ :contract_method, :estimated_price, :contract_documents ],
    "e-procurement-guide"     => [ :contract_method, :contract_documents ],
    "contract-execution"      => [ :contract_method, :contract_documents, :contract_guarantee, :cost_estimate ],
    "contract-guarantee-deposit" => [ :contract_guarantee, :contract_documents ],
    "estimated-price"         => [ :estimated_price, :cost_estimate, :budget_estimator ],
    "inspection"              => [ :progress_inspection, :contract_documents ],
    "payment"                 => [ :progress_inspection, :contract_documents ],
    "design-change"           => [ :design_change, :progress_inspection ],
    "price-escalation"        => [ :design_change, :estimated_price ],
    "late-penalty"            => [ :contract_documents ],
    "defect-warranty"         => [ :contract_documents, :progress_inspection ],
    "contract-termination"    => [ :contract_documents ],
    "joint-contract"          => [ :contract_method, :contract_documents ],
    "subcontract"             => [ :contract_documents ],
    "goods-selection-committee" => [ :contract_method, :contract_documents, :quote_review ],
    "travel-expense"          => [ :travel_calculator ],
    "budget-carryover"        => [ :budget_estimator ],
    "year-end-settlement"     => [],
    # 2026-02-18 추가
    "advance-payment"         => [ :contract_documents, :progress_inspection ],
    "bid-qualification"       => [ :contract_method, :estimated_price ],
    "bid-deposit"             => [ :contract_method, :contract_documents ],
    "long-term-contract"      => [ :contract_method, :contract_documents ],
    "unit-price-contract"     => [ :contract_method, :contract_documents ],
    "spec-price-split-bid"    => [ :contract_method, :estimated_price ],
    "performance-guarantee"   => [ :contract_guarantee, :contract_documents ],
    "multiple-price"          => [ :estimated_price, :legal_period ],
    # 2026-02-22 추가
    "lowest-bid-rate"         => [ :estimated_price, :legal_period, :contract_method ],
    "quote-collection-guide"  => [ :quote_review, :contract_method, :contract_documents ],
    # 2026-02-25 추가
    "completion-payment-checklist" => [ :progress_inspection, :contract_documents ]
  }.freeze

  # 플로차트가 있는 토픽 목록
  FLOWCHART_SLUGS = %w[
    price-negotiation private-contract private-contract-limit private-contract-amount
    emergency-contract dual-quote single-quote travel-expense year-end-settlement
    budget-carryover late-penalty contract-guarantee-deposit subcontract bid-announcement
    bidding bid-qualification long-term-contract multiple-price spec-price-split-bid
    advance-payment unit-price-contract performance-guarantee e-bidding estimated-price
    contract-execution inspection payment design-change price-escalation contract-termination
    joint-contract defect-warranty bid-deposit small-amount-contract budget-compilation
    split-contract-prohibition quote-collection-guide lowest-bid-rate e-procurement-guide
    goods-selection-committee
    qualification-failure contract-guarantee-exemption private-contract-justification
    goods-vs-service-contract bid-participation-restriction additional-contract-limit
    penalty-reduction-procedure contract-period-extension e-bidding-error-faq
    contract-amount-adjustment completion-payment-checklist
  ].freeze

  # 토픽별 개별 아이콘 매핑
  TOPIC_ICONS = {
    "private-contract"           => "handshake",
    "private-contract-overview"  => "handshake",
    "private-contract-limit"     => "rule",
    "private-contract-amount"    => "calculate",
    "single-quote"               => "person",
    "dual-quote"                 => "group",
    "emergency-contract"         => "emergency",
    "price-negotiation"          => "forum",
    "bidding"                    => "gavel",
    "bid-announcement"           => "campaign",
    "e-bidding"                  => "computer",
    "e-procurement-guide"        => "shopping_cart",
    "contract-execution"         => "description",
    "contract-guarantee-deposit" => "security",
    "estimated-price"            => "calculate",
    "inspection"                 => "fact_check",
    "payment"                    => "payments",
    "design-change"              => "edit_note",
    "price-escalation"           => "trending_up",
    "late-penalty"               => "schedule",
    "defect-warranty"            => "verified_user",
    "contract-termination"       => "cancel",
    "joint-contract"             => "groups",
    "subcontract"                => "account_tree",
    "goods-selection-committee"  => "inventory_2",
    "travel-expense"             => "flight_takeoff",
    "year-end-settlement"        => "receipt_long",
    "budget-carryover"           => "savings",
    # 2026-02-18 추가
    "advance-payment"            => "payments",
    "bid-qualification"          => "fact_check",
    "bid-deposit"                => "lock",
    "long-term-contract"         => "event_repeat",
    "unit-price-contract"        => "price_change",
    "spec-price-split-bid"       => "call_split",
    "performance-guarantee"      => "verified",
    "multiple-price"             => "format_list_numbered",
    # 2026-02-22 추가
    "lowest-bid-rate"            => "trending_down",
    "quote-collection-guide"     => "description",
    # 2026-02-25 추가
    "completion-payment-checklist" => "checklist"
  }.freeze

  CATEGORY_CONFIG = {
    "contract" => { label: "계약",      color: "indigo",  icon: "gavel",             desc: "수의계약 요건부터 대금지급까지 — 입찰·계약체결·변경 전 과정을 단계별로 안내합니다" },
    "budget"   => { label: "예산/결산", color: "blue",    icon: "account_balance",   desc: "예산 편성부터 결산까지 — 이체·추경·예비비 처리를 실무 중심으로 정리합니다" },
    "expense"  => { label: "지출",      color: "amber",   icon: "receipt_long",      desc: "지출 원인행위·채무부담행위를 올바르게 처리하는 실무 기준을 안내합니다" },
    "salary"   => { label: "급여/수당", color: "emerald", icon: "payments",          desc: "봉급·수당·성과상여·퇴직수당 계산 기준과 지급 절차를 명확히 안내합니다" },
    "subsidy"  => { label: "보조금",    color: "violet",  icon: "volunteer_activism", desc: "국고보조금·교부금 집행 기준과 정산 실수를 예방하는 핵심 사항을 정리합니다" },
    "property" => { label: "공유재산",  color: "teal",    icon: "domain",            desc: "공유재산 취득·관리·처분 시 꼭 확인해야 할 법령 근거와 절차를 안내합니다" },
    "travel"   => { label: "여비/출장", color: "rose",    icon: "flight_takeoff",    desc: "국내·해외 출장 여비 지급 기준과 정산 방법을 헷갈리지 않게 정리합니다" },
    "duty"     => { label: "복무",      color: "orange",  icon: "badge",             desc: "휴가·휴직·파견·징계 등 복무 관련 법령 기준과 유의사항을 상세히 안내합니다" },
    "other"    => { label: "기타",      color: "slate",   icon: "folder_open",       desc: "계약·예산·복무 외 공무원 실무에서 자주 참고하는 법령을 모아 정리합니다" }
  }.freeze

  CATEGORY_ORDER = %w[contract budget expense salary subsidy property travel duty other].freeze

  TOOL_DEFINITIONS = {
    contract_method:   { icon: "gavel",        title: "계약방식 결정",   desc: "금액 입력 → 방식 바로 확인", color: "emerald" },
    contract_documents: { icon: "fact_check",   title: "서류 체크리스트", desc: "필요 서류 원클릭 생성",       color: "indigo" },
    contract_reason:   { icon: "description",  title: "계약사유서 작성", desc: "수의계약 사유서 자동 작성",   color: "violet" },
    quote_review:      { icon: "receipt_long", title: "견적서 검토",     desc: "견적서 적정성 자동 분석",     color: "amber" },
    estimated_price:   { icon: "calculate",    title: "추정가격 계산기", desc: "부가세 포함 추정가격 산출",   color: "blue" },
    cost_estimate:     { icon: "attach_money", title: "원가계산서",      desc: "원가 항목별 자동 계산",       color: "teal" },
    budget_estimator:  { icon: "account_balance", title: "소요예산 추정", desc: "대략적인 예산 미리 산출",    color: "slate" },
    contract_guarantee: { icon: "security",     title: "계약보증금 계산", desc: "보증금 요율 자동 계산",       color: "rose" },
    progress_inspection: { icon: "engineering", title: "기성검사 체크",   desc: "기성·준공 검사 항목 확인",    color: "orange" },
    design_change:     { icon: "edit_note",    title: "설계변경 계산",   desc: "변경 금액 자동 산출",         color: "purple" },
    legal_period:      { icon: "calendar_today", title: "법정기간 계산", desc: "입찰공고 기간 자동 산출",     color: "sky" },
    travel_calculator: { icon: "flight_takeoff", title: "여비계산기",    desc: "출장 여비 자동 계산",         color: "rose" }
  }.freeze

  # 계약 카테고리 토픽을 6개 서브그룹으로 분류
  # 각 그룹: { id:, label:, icon:, desc:, slugs:, topics: }
  CONTRACT_SUBGROUP_DEFS = [
    { id: "private-contract", label: "수의계약",   icon: "handshake",     desc: "수의계약 요건, 한도, 견적 절차",
      slugs: %w[private-contract private-contract-limit private-contract-amount
                single-quote dual-quote quote-collection-guide private-contract-justification
                price-negotiation emergency-contract small-amount-contract] },
    { id: "bidding",          label: "경쟁입찰",   icon: "gavel",         desc: "입찰공고, 전자입찰, 예정가격, 적격심사",
      slugs: %w[bidding bid-announcement e-bidding estimated-price multiple-price
                lowest-bid-rate bid-qualification spec-price-split-bid goods-selection-committee
                bid-participation-restriction qualification-failure e-bidding-error-faq] },
    { id: "execution",        label: "계약체결",   icon: "description",   desc: "계약서 작성, 전자계약, 특수계약, 계약 유형 구분",
      slugs: %w[contract-execution e-procurement-guide unit-price-contract long-term-contract
                joint-contract subcontract split-contract-prohibition goods-vs-service-contract] },
    { id: "guarantee",        label: "보증금/담보", icon: "security",      desc: "계약보증금, 입찰보증금, 이행보증, 하자보증",
      slugs: %w[contract-guarantee-deposit bid-deposit performance-guarantee defect-warranty
                contract-guarantee-exemption] },
    { id: "performance",      label: "계약이행",   icon: "engineering",   desc: "검수, 대금지급, 선금, 지체상금, 준공",
      slugs: %w[inspection payment advance-payment late-penalty
                penalty-reduction-procedure completion-payment-checklist] },
    { id: "change",           label: "변경/종료",  icon: "edit_note",     desc: "설계변경, 물가변동, 계약금액 조정, 계약해제",
      slugs: %w[design-change price-escalation contract-termination
                additional-contract-limit contract-period-extension contract-amount-adjustment] }
  ].freeze
end
