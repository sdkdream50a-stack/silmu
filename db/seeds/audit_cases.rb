cases = [
  # === 수의계약 분야 ===
  {
    slug: "private-contract-over-limit",
    title: "수의계약 한도액 초과 계약 체결",
    category: "수의계약",
    severity: "중대",
    issue: "추정가격 2,200만원인 물품 구매를 수의계약으로 체결하였으나, 물품 수의계약 한도액(추정가격 2천만원 이하)을 초과하는 것으로 확인됨. 부가가치세를 포함한 금액을 추정가격으로 잘못 산정하여 한도 이내로 착각한 사례.",
    legal_basis: "지방계약법 시행령 제25조",
    action_taken: "관련자 경고, 향후 추정가격 산정 시 부가세 제외 기준 준수 지시",
    lesson: "추정가격은 부가가치세를 제외한 금액으로 산정해야 합니다. VAT 포함/미포함 기준을 혼동하면 수의계약 한도를 초과하거나, 반대로 경쟁입찰 대상을 수의계약으로 처리하는 오류가 발생할 수 있습니다.",
    detail: "추정가격 산정 시 부가가치세는 제외하는 것이 원칙입니다(지방계약법 시행령 제7조). 이 사례에서는 업체 견적서상 부가세 포함 금액 2,420만원에서 부가세를 뺀 2,200만원을 추정가격으로 산정해야 했으나, 견적서 합계액을 그대로 추정가격으로 사용한 것이 문제였습니다.\n\n수의계약 물품 한도액은 추정가격 2천만원 이하이므로, 정확한 추정가격 산정이 수의계약 적법성의 출발점입니다.",
    topic_slug: "private-contract-amount"
  },
  {
    slug: "private-contract-split",
    title: "수의계약 분할 발주 (계약 쪼개기)",
    category: "수의계약",
    severity: "중대",
    issue: "총 사업비 6,000만원인 물품 구매를 3건(각 2,000만원)으로 분할하여 수의계약을 체결함. 동일 목적의 사업을 의도적으로 분리 발주하여 수의계약 한도 이내로 맞춘 것으로 판단됨.",
    legal_basis: "지방계약법 제9조, 시행령 제25조",
    action_taken: "계약 취소, 관련자 중징계(감봉), 향후 동일 사업 분할 발주 금지 재교육",
    lesson: "동일 목적·동일 시기의 사업을 의도적으로 분할하여 수의계약 한도 이내로 맞추는 것은 '계약 쪼개기'로 엄격히 금지됩니다. 적발 시 중징계 대상이며, 계약 자체가 무효가 될 수 있습니다.",
    detail: "계약 분할(쪼개기)은 감사에서 가장 자주 지적되는 사항 중 하나입니다. 다음의 경우 분할 발주로 판단됩니다:\n\n1. 동일한 사업 목적\n2. 동일한 시기(연도 내)\n3. 동일한 계약상대자\n4. 계약 건들 사이에 연관성이 있음\n\n다만, 예산 배정이 다르거나 사업 목적이 명확히 다른 경우는 분할 발주에 해당하지 않습니다.",
    topic_slug: "private-contract"
  },
  {
    slug: "private-contract-no-quote",
    title: "2인 견적 미징구 수의계약",
    category: "수의계약",
    severity: "보통",
    issue: "추정가격 1,500만원인 용역 계약에서 2인 이상 견적서를 징구해야 함에도 1인 견적만으로 수의계약을 체결함.",
    legal_basis: "지방계약법 시행령 제25조 제1항 제5호, 제30조",
    action_taken: "관련자 주의, 견적서 징구 절차 준수 지시",
    lesson: "추정가격 구간에 따른 견적 징구 기준(1인/2인)을 정확히 구분해야 합니다. 지방계약법 시행령 제30조에 따라 소액수의계약 시에도 견적서 징구 기준을 준수해야 합니다.",
    topic_slug: "dual-quote"
  },
  {
    slug: "private-contract-same-vendor",
    title: "특정 업체 반복 수의계약",
    category: "수의계약",
    severity: "보통",
    issue: "동일 업체와 연간 15건의 물품 수의계약을 체결하면서, 타 업체 견적 비교 없이 해당 업체만 지명하여 계약함. 경쟁 원칙 위반 및 특혜 의심.",
    legal_basis: "지방계약법 제9조, 시행령 제25조",
    action_taken: "관련자 경고, 수의계약 업체 선정 시 경쟁성 확보 방안 마련 지시",
    lesson: "수의계약이라도 가능한 한 2인 이상 견적 비교를 통해 경쟁성을 확보해야 합니다. 특정 업체와 반복적으로 수의계약하면 특혜 시비가 발생할 수 있으므로, 업체 풀을 다양하게 관리해야 합니다.",
    topic_slug: "private-contract"
  },
  {
    slug: "emergency-contract-unjustified",
    title: "긴급수의계약 사유 부적정",
    category: "수의계약",
    severity: "중대",
    issue: "연말 예산 집행을 위해 '긴급 행정수요'를 사유로 긴급수의계약(특명수의)을 체결함. 실제로는 연초부터 계획 가능했던 사업을 12월에 급히 집행한 것으로, 진정한 긴급성이 인정되지 않음.",
    legal_basis: "지방계약법 시행령 제25조 제1항 제4호",
    action_taken: "관련자 감봉, 긴급수의계약 승인 절차 강화",
    lesson: "긴급수의계약은 천재지변, 비상사태, 긴급복구 등 진정한 긴급 사유가 있어야 합니다. 단순 예산 소진이나 업무 편의를 위한 긴급수의는 감사에서 반드시 지적됩니다.",
    topic_slug: "emergency-contract"
  },

  # === 입찰 분야 ===
  {
    slug: "bid-period-insufficient",
    title: "공고기간 부족 입찰",
    category: "입찰",
    severity: "중대",
    issue: "추정가격 15억원 공사를 7일 공고로 입찰 실시함. 10억원 이상~50억원 미만은 최소 15일 이상 공고해야 하나 미준수.",
    legal_basis: "지방계약법 시행령 제16조",
    action_taken: "입찰 무효, 재입찰 실시, 관련자 경고",
    lesson: "추정가격 구간별 최소 공고기간을 정확히 숙지해야 합니다. 10억 미만(7일), 10~50억(15일), 50억 이상(40일)을 혼동하면 입찰 자체가 무효 처리됩니다.",
    topic_slug: "bid-announcement"
  },
  {
    slug: "bid-unfair-spec",
    title: "특정 업체 유리한 입찰 규격 설정",
    category: "입찰",
    severity: "중대",
    issue: "물품 구매 입찰 시 특정 제조사의 제품만 충족 가능한 규격을 설정하여 사실상 1개 업체만 입찰 참가가 가능한 상황을 조성함.",
    legal_basis: "지방계약법 제9조, 입찰 및 계약집행기준",
    action_taken: "입찰 취소, 규격서 재작성 후 재입찰, 물품선정위원회 운영 의무화",
    lesson: "규격서에 특정 상표·브랜드명을 기재하면 안 되며, '동등 이상'으로 표기해야 합니다. 불필요하게 경쟁을 제한하는 규격 설정은 감사 지적의 주요 대상입니다.",
    topic_slug: "bidding"
  },
  {
    slug: "bid-rebid-condition-change",
    title: "재공고 입찰 시 조건 임의 변경",
    category: "입찰",
    severity: "보통",
    issue: "유찰 후 재공고 시 참가자격을 최초 공고보다 완화하여 재공고입찰로 진행함. 재공고 시에는 최초 공고와 동일한 조건이어야 하나 이를 위반.",
    legal_basis: "지방계약법 시행령 제16조의2",
    action_taken: "재공고 무효, 신규 공고로 재진행, 관련자 주의",
    lesson: "재공고입찰은 최초 공고와 동일한 조건이어야 합니다. 조건을 변경하려면 재공고가 아닌 '신규 공고'로 처리해야 합니다.",
    topic_slug: "bid-announcement"
  },
  {
    slug: "bid-qualification-excessive",
    title: "과도한 입찰 참가자격 제한",
    category: "입찰",
    severity: "보통",
    issue: "추정가격 5,000만원 물품 구매에 '최근 3년간 동종 납품실적 3건 이상'이라는 과도한 참가자격을 설정하여 경쟁을 부당 제한함.",
    legal_basis: "지방계약법 제9조, 시행령 제13조",
    action_taken: "참가자격 완화 후 재공고, 관련자 주의",
    lesson: "참가자격 제한은 계약 목적 달성에 필요한 최소한으로 설정해야 합니다. 특히 소규모 계약에서 과도한 실적 요건은 경쟁 제한으로 지적됩니다.",
    topic_slug: "bidding"
  },

  # === 계약체결 분야 ===
  {
    slug: "contract-late-execution",
    title: "계약체결 지연 (기한 초과)",
    category: "계약체결",
    severity: "경미",
    issue: "낙찰자 결정 후 10일 이내 계약을 체결해야 하나, 내부 결재 지연으로 18일 경과 후 계약 체결함.",
    legal_basis: "지방계약법 시행령 제49조",
    action_taken: "관련자 주의, 계약체결 기한 관리 강화",
    lesson: "낙찰 통지 후 10일 이내 계약 체결이 원칙입니다. 내부 행정 지연은 정당한 사유가 되지 않으므로, 낙찰 직후 계약서 준비를 병행해야 합니다.",
    topic_slug: "contract-execution"
  },
  {
    slug: "contract-guarantee-exemption-wrong",
    title: "계약보증금 면제 요건 미충족",
    category: "계약체결",
    severity: "보통",
    issue: "계약금액 8,000만원 물품 계약에서 계약보증금을 면제함. 물품의 경우 5,000만원 이하만 면제 가능하나 기준을 초과함.",
    legal_basis: "지방계약법 시행령 제37조",
    action_taken: "계약보증금 추징, 관련자 경고",
    lesson: "계약보증금 면제 기준(물품·용역 5,000만원 이하, 공사 1억원 이하)을 정확히 숙지해야 합니다. 면제 요건에 해당하지 않는 경우 반드시 보증금을 납부받아야 합니다.",
    topic_slug: "contract-guarantee-deposit"
  },
  {
    slug: "contract-no-guarantee-forfeiture",
    title: "계약 불이행 시 보증금 미귀속",
    category: "계약체결",
    severity: "보통",
    issue: "계약상대자가 계약 이행을 포기했음에도 계약보증금을 세입 귀속 조치하지 않고 반환함.",
    legal_basis: "지방계약법 시행령 제39조",
    action_taken: "보증금 세입 귀속 조치, 관련자 주의",
    lesson: "계약상대자의 귀책사유로 계약이 해제·해지된 경우 계약보증금은 반드시 세입에 귀속시켜야 합니다. 동정심이나 업무 편의로 반환하면 감사 지적 대상입니다.",
    topic_slug: "contract-guarantee-deposit"
  },

  # === 계약이행 분야 ===
  {
    slug: "inspection-delayed",
    title: "검사 지연 (14일 초과)",
    category: "계약이행",
    severity: "경미",
    issue: "물품 납품 후 이행 완료 신고를 받고도 25일이 경과한 후 검사를 실시함. 검사는 신고 후 14일 이내 완료해야 함.",
    legal_basis: "지방계약법 시행령 제64조",
    action_taken: "관련자 주의, 검사 기한 관리 체계 구축",
    lesson: "이행 완료 신고 접수 후 14일 이내 검사를 완료해야 합니다. 검사 지연은 대금 지급 지연으로 이어지고, 지연이자 부담이 발생할 수 있습니다.",
    topic_slug: "inspection"
  },
  {
    slug: "inspection-by-requester",
    title: "계약 요청 부서가 검사 실시",
    category: "계약이행",
    severity: "보통",
    issue: "물품 구매를 요청한 부서의 직원이 검사자로 지정되어 검사를 실시함. 계약 요청자와 검사자의 분리 원칙 위반.",
    legal_basis: "지방계약법 시행령 제64조, 입찰 및 계약집행기준",
    action_taken: "향후 검사자 지정 시 요청 부서 외 인력으로 배정, 관련자 주의",
    lesson: "검사의 공정성을 위해 계약 요청 부서와 검사 담당은 분리해야 합니다. 동일 부서 직원이 요청과 검사를 모두 수행하면 견제 기능이 작동하지 않습니다.",
    topic_slug: "inspection"
  },
  {
    slug: "late-penalty-not-imposed",
    title: "지체상금 미징수",
    category: "계약이행",
    severity: "보통",
    issue: "공사 계약에서 준공기한을 15일 초과하여 완공했으나 지체상금을 징수하지 않음. 계약금액 5억원 × 15일 × 0.5/1,000 = 375만원 미징수.",
    legal_basis: "지방계약법 제30조, 시행령 제74조",
    action_taken: "지체상금 375만원 추징, 관련자 경고",
    lesson: "이행기한을 초과한 경우 지체상금을 반드시 징수해야 합니다. 정당한 면제 사유(천재지변, 발주기관 귀책 등)가 없는 한 임의 면제는 불가합니다.",
    topic_slug: "late-penalty"
  },
  {
    slug: "late-penalty-wrong-rate",
    title: "지체상금률 잘못 적용",
    category: "계약이행",
    severity: "경미",
    issue: "물품 계약에 공사 지체상금률(0.5/1,000)을 적용함. 물품은 0.75/1,000을 적용해야 하나, 계약 유형별 요율을 혼동.",
    legal_basis: "지방계약법 시행령 제74조",
    action_taken: "차액 추징, 관련자 주의",
    lesson: "지체상금률은 계약 유형에 따라 다릅니다. 공사(0.5/1,000), 물품·용역(0.75/1,000), 임대차(1/1,000). 유형별 요율을 정확히 적용해야 합니다.",
    topic_slug: "late-penalty"
  },
  {
    slug: "defect-warranty-short-period",
    title: "하자담보책임기간 부족 설정",
    category: "계약이행",
    severity: "보통",
    issue: "건축물 구조체 하자담보책임기간을 3년으로 설정함. 구조체는 5년이 법정 최소기간이나 이를 단축 적용.",
    legal_basis: "지방계약법 시행령 제69조",
    action_taken: "하자담보책임기간 5년으로 정정, 추가 하자보증금 징구, 관련자 주의",
    lesson: "하자담보책임기간은 공종별로 법에서 정한 최소기간 이상이어야 합니다. 구조체(5년), 방수(3년), 설비(2년), 도장(1년) 등 공종별 기간을 정확히 적용해야 합니다.",
    topic_slug: "defect-warranty"
  },
  {
    slug: "defect-warranty-no-deposit",
    title: "하자보증금 미징구",
    category: "계약이행",
    severity: "보통",
    issue: "계약금액 3억원 공사의 준공 시 하자보증금을 징구하지 않고 계약을 종료함. 하자보증금(계약금액의 2~5%)은 반드시 납부받아야 함.",
    legal_basis: "지방계약법 시행령 제70조",
    action_taken: "하자보증금 소급 징구, 관련자 경고",
    lesson: "공사 계약 준공 시 하자보증금(2~5%)은 반드시 징구해야 합니다. 하자보증금 없이 계약을 종료하면 하자 발생 시 보수 비용을 확보할 수 없습니다.",
    topic_slug: "defect-warranty"
  },

  # === 대금지급 분야 ===
  {
    slug: "payment-before-inspection",
    title: "검사 완료 전 대금 지급",
    category: "대금지급",
    severity: "중대",
    issue: "물품 검수를 완료하기 전에 대금을 선지급함. 검사 합격 후 대가를 지급해야 하는 절차를 위반.",
    legal_basis: "지방계약법 제16조의2, 시행령 제68조",
    action_taken: "관련자 감봉, 향후 검사-대금지급 절차 분리 엄수",
    lesson: "대가 지급은 반드시 검사(검수) 합격 후에 이루어져야 합니다. 검사 전 대금 지급은 부실 납품의 원인이 되며, 감사에서 가장 심각하게 지적됩니다.",
    topic_slug: "payment"
  },
  {
    slug: "payment-advance-misuse",
    title: "선금 사용 용도 위반",
    category: "대금지급",
    severity: "보통",
    issue: "공사 선금 7,000만원을 해당 공사가 아닌 다른 사업장의 자재 구매에 사용함. 선금은 해당 계약 목적에만 사용해야 함.",
    legal_basis: "지방계약법 제17조, 시행령 제53조",
    action_taken: "선금 전액 반환 및 선금 지급 제한, 관련자 주의",
    lesson: "선금은 해당 계약의 이행에만 사용해야 합니다. 타 용도 전용 시 선금 반환 및 향후 선금 지급 제한 등 불이익이 발생합니다.",
    topic_slug: "payment"
  },
  {
    slug: "payment-delay-no-interest",
    title: "대금 지급 지연 후 지연이자 미지급",
    category: "대금지급",
    severity: "경미",
    issue: "검사 완료 후 대가 지급 기한(5일)을 12일 초과하여 지급하면서, 지연일수에 대한 지연이자를 지급하지 않음.",
    legal_basis: "지방계약법 제16조의2, 시행령 제68조의2",
    action_taken: "지연이자 추가 지급, 관련자 주의",
    lesson: "대가 지급 기한을 초과한 경우 지연이자를 반드시 지급해야 합니다. 지연이자 미지급은 업체의 재무 부담을 가중시키고 감사 지적 대상입니다.",
    topic_slug: "payment"
  },

  # === 하도급 분야 ===
  {
    slug: "subcontract-whole-transfer",
    title: "일괄하도급(불법 전대) 적발",
    category: "하도급",
    severity: "중대",
    issue: "원도급자가 계약 공사의 90% 이상을 단일 하수급인에게 일괄 하도급함. 직접시공 50% 이상 의무를 위반한 사실상의 일괄하도급.",
    legal_basis: "지방계약법 제18조, 건설산업기본법 제29조",
    action_taken: "계약 해지, 부정당업자 제재(2년), 관련자 중징계",
    lesson: "일괄하도급은 공공계약에서 절대 금지됩니다. 원도급자는 해당 공사의 50% 이상을 직접 시공해야 하며, 이를 위반하면 계약 해지 및 부정당업자 제재를 받습니다.",
    topic_slug: "subcontract"
  },
  {
    slug: "subcontract-no-notice",
    title: "하도급 통지 누락",
    category: "하도급",
    severity: "경미",
    issue: "원도급자가 하도급 계약을 체결한 후 발주기관에 하도급 통지를 하지 않음. 하도급 통지는 계약 체결일로부터 30일 이내에 해야 함.",
    legal_basis: "지방계약법 시행령 제56조",
    action_taken: "하도급 통지서 즉시 접수, 원도급자 주의",
    lesson: "하도급 계약 체결 시 발주기관에 30일 이내 통지는 의무사항입니다. 무통지 하도급은 하도급 관리 부실의 시작점이며, 근로자 보호에도 문제가 됩니다.",
    topic_slug: "subcontract"
  },
  {
    slug: "subcontract-direct-payment-denied",
    title: "하도급대금 직접지급 미이행",
    category: "하도급",
    severity: "보통",
    issue: "하수급인이 하도급대금 직접지급을 요청했으나, 원도급자의 동의가 없다는 이유로 거부함. 법정 직접지급 사유에 해당하면 원도급자 동의 불요.",
    legal_basis: "지방계약법 시행령 제58조, 하도급법 제14조",
    action_taken: "하도급대금 직접지급 실시, 관련 담당자 교육",
    lesson: "법정 직접지급 사유(원도급자 부도, 하도급대금 2회 이상 미지급 등)에 해당하면 원도급자의 동의 없이도 하도급대금을 직접 지급해야 합니다.",
    topic_slug: "subcontract"
  },

  # === 기타 분야 ===
  {
    slug: "estimated-price-leak",
    title: "예정가격 사전 누설",
    category: "입찰",
    severity: "중대",
    issue: "예정가격 작성 담당자가 입찰 전 특정 업체에 예정가격 정보를 누설함. 전자입찰 시스템의 예정가격 조회 기록에서 비정상적 접근 확인.",
    legal_basis: "지방계약법 시행령 제8조, 형법 제127조(공무상 비밀누설)",
    action_taken: "관련자 파면, 형사 고발, 입찰 무효 처리",
    lesson: "예정가격은 개찰 전까지 절대 비공개 원칙입니다. 누설 시 형사처벌(5년 이하 징역)까지 가능한 중대 위반사항입니다. 시스템 접근 로그가 남으므로 적발 가능성이 매우 높습니다.",
    topic_slug: "estimated-price"
  },
  {
    slug: "estimated-price-no-research",
    title: "예정가격 시장조사 미실시",
    category: "입찰",
    severity: "경미",
    issue: "예정가격 작성 시 거래실례가격 조사 없이 업체 견적서 1장만으로 예정가격을 결정함. 최소 2개 이상 가격자료 비교가 원칙.",
    legal_basis: "지방계약법 시행령 제7조, 제9조",
    action_taken: "관련자 주의, 예정가격 작성 기준 재교육",
    lesson: "예정가격은 거래실례가격, 원가계산, 감정가격 등 객관적 자료를 바탕으로 작성해야 합니다. 견적서 1장만으로 예정가격을 결정하면 적정성을 입증할 수 없습니다.",
    topic_slug: "estimated-price"
  },
  {
    slug: "design-change-unapproved",
    title: "설계변경 미승인 시공",
    category: "계약이행",
    severity: "보통",
    issue: "현장 여건 변경으로 설계와 다르게 시공한 후 사후 설계변경을 신청함. 설계변경은 사전 승인이 원칙이며 사후 변경은 인정 불가.",
    legal_basis: "지방계약법 시행령 제65조",
    action_taken: "미승인 시공분 계약금액 미반영, 관련자 주의",
    lesson: "설계변경은 반드시 시공 전에 승인을 받아야 합니다. '일단 시공하고 나중에 변경' 방식은 설계변경으로 인정되지 않으며, 비용을 인정받을 수 없습니다.",
    topic_slug: "design-change"
  },
  {
    slug: "price-escalation-below-threshold",
    title: "물가변동 조정 요건 미충족 조정",
    category: "계약이행",
    severity: "보통",
    issue: "등락률이 2.8%에 불과한데 물가변동 조정을 실시함. 3% 이상이어야 조정 가능하나 기준 미달.",
    legal_basis: "지방계약법 시행령 제65조",
    action_taken: "부당 조정금액 환수, 관련자 주의",
    lesson: "물가변동 조정은 입찰일 기준 90일 경과 + 등락률 3% 이상 두 요건을 모두 충족해야 합니다. 요건 미충족 상태에서의 조정은 부당지출로 지적됩니다.",
    topic_slug: "price-escalation"
  },
  {
    slug: "joint-contract-nominal",
    title: "공동도급 형식적 참여 (명의대여)",
    category: "입찰",
    severity: "중대",
    issue: "공동도급 구성원 중 1개 업체가 실제 시공에 전혀 참여하지 않고 명의만 대여한 것으로 확인됨. 지분율 20%를 배정받았으나 실질적 이행 없음.",
    legal_basis: "지방계약법 시행령 제88조, 건설산업기본법",
    action_taken: "부정당업자 제재(명의대여 업체 및 대여받은 업체 모두), 관련자 징계",
    lesson: "공동도급 구성원은 배정된 지분율에 상응하는 실질적 이행을 해야 합니다. 명의만 대여하는 행위는 부정당업자 제재 사유이며, 실제 참여 여부를 감사에서 면밀히 검토합니다.",
    topic_slug: "joint-contract"
  },
  {
    slug: "e-bidding-offline-processed",
    title: "전자입찰 의무 대상 서면 처리",
    category: "입찰",
    severity: "보통",
    issue: "추정가격 5,000만원 물품 구매를 나라장터 전자입찰이 아닌 서면입찰로 진행함. 2,000만원 초과 계약은 전자조달 의무화 대상.",
    legal_basis: "전자조달법 시행령 제6조",
    action_taken: "서면입찰 결과 무효, 전자입찰로 재진행, 관련자 주의",
    lesson: "추정가격 2,000만원 초과 계약은 나라장터(G2B) 전자입찰이 의무입니다. 시스템 장애 등 불가피한 사유 없이 서면으로 처리하면 입찰이 무효가 됩니다.",
    topic_slug: "e-bidding"
  },
  {
    slug: "contract-termination-no-notice",
    title: "이행 최고 없이 계약 해지",
    category: "계약이행",
    severity: "보통",
    issue: "계약상대자의 이행 지체를 사유로 사전 이행 최고(독촉) 없이 곧바로 계약을 해지함. 해지 전 상당 기간을 정하여 이행을 최고해야 함.",
    legal_basis: "지방계약법 시행령 제60조",
    action_taken: "해지 처분 취소, 이행 최고 후 재결정, 관련자 주의",
    lesson: "계약 해제·해지 전에는 반드시 상당 기간을 정하여 이행을 최고(독촉)해야 합니다. 사전 절차 없는 해지는 위법하며, 발주기관이 손해배상 책임을 질 수 있습니다.",
    topic_slug: "contract-termination"
  }
]

cases.each do |c|
  AuditCase.find_or_create_by!(slug: c[:slug]) do |ac|
    ac.title = c[:title]
    ac.category = c[:category]
    ac.severity = c[:severity]
    ac.issue = c[:issue]
    ac.legal_basis = c[:legal_basis]
    ac.action_taken = c[:action_taken]
    ac.lesson = c[:lesson]
    ac.detail = c[:detail]
    ac.topic_slug = c[:topic_slug]
    ac.published = true
  end
end

puts "감사사례 #{cases.size}건 생성 완료!"
