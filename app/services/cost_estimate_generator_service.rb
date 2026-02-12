# 물량내역서 + 시방서 생성 서비스
# 소액공사에서 설계서 대신 사용하는 간이 물량내역서와 시방서를 생성
class CostEstimateGeneratorService
  # 공사 유형별 기본 항목 템플릿
  CONSTRUCTION_TYPES = {
    repair: {
      name: "시설물보수",
      icon: "home_repair_service",
      desc: "건물 보수·수선 공사",
      default_items: [
        { name: "철거 및 정리", spec: "기존 마감재 철거", unit: "식", qty: 1 },
        { name: "벽체 보수", spec: "시멘트 모르타르", unit: "m²", qty: 0 },
        { name: "바닥 보수", spec: "에폭시 모르타르", unit: "m²", qty: 0 },
        { name: "마감재 시공", spec: "해당 자재", unit: "m²", qty: 0 },
        { name: "부대공사", spec: "잡자재 등", unit: "식", qty: 1 }
      ]
    },
    painting: {
      name: "도장공사",
      icon: "format_paint",
      desc: "내·외부 도장 공사",
      default_items: [
        { name: "기존 도막 제거", spec: "스크래핑·샌딩", unit: "m²", qty: 0 },
        { name: "바탕처리", spec: "퍼티·프라이머", unit: "m²", qty: 0 },
        { name: "하도", spec: "프라이머 1회", unit: "m²", qty: 0 },
        { name: "중도", spec: "중도 도료 1회", unit: "m²", qty: 0 },
        { name: "상도", spec: "상도 도료 2회", unit: "m²", qty: 0 },
        { name: "양생·보양", spec: "마스킹테이프 등", unit: "식", qty: 1 }
      ]
    },
    waterproof: {
      name: "방수공사",
      icon: "water_drop",
      desc: "옥상·지하 방수 공사",
      default_items: [
        { name: "기존 방수층 철거", spec: "기계·인력", unit: "m²", qty: 0 },
        { name: "바탕정리", spec: "먼지 제거·건조", unit: "m²", qty: 0 },
        { name: "프라이머 도포", spec: "우레탄 프라이머", unit: "m²", qty: 0 },
        { name: "방수층 시공", spec: "우레탄 도막방수", unit: "m²", qty: 0 },
        { name: "보호층 시공", spec: "시멘트 모르타르", unit: "m²", qty: 0 },
        { name: "배수구 정비", spec: "드레인 교체", unit: "개소", qty: 0 }
      ]
    },
    electrical: {
      name: "전기공사",
      icon: "electrical_services",
      desc: "전기·조명·통신 공사",
      default_items: [
        { name: "배선공사", spec: "CV 케이블", unit: "m", qty: 0 },
        { name: "배관공사", spec: "PVC 전선관", unit: "m", qty: 0 },
        { name: "조명기구 설치", spec: "LED 등기구", unit: "개", qty: 0 },
        { name: "스위치·콘센트", spec: "매입형", unit: "개", qty: 0 },
        { name: "분전반 설치", spec: "ELB 포함", unit: "면", qty: 0 },
        { name: "접지공사", spec: "접지동봉", unit: "개소", qty: 0 }
      ]
    },
    plumbing: {
      name: "설비공사",
      icon: "plumbing",
      desc: "급·배수, 냉난방 설비 공사",
      default_items: [
        { name: "배관공사", spec: "PVC·스텐 배관", unit: "m", qty: 0 },
        { name: "위생기구 설치", spec: "양변기·세면기 등", unit: "조", qty: 0 },
        { name: "밸브류 설치", spec: "게이트밸브 등", unit: "개", qty: 0 },
        { name: "보온공사", spec: "배관 보온재", unit: "m", qty: 0 },
        { name: "시운전 및 누수시험", spec: "수압시험", unit: "식", qty: 1 }
      ]
    },
    landscape: {
      name: "조경공사",
      icon: "park",
      desc: "식재·포장·시설물 공사",
      default_items: [
        { name: "식재공사", spec: "교목·관목", unit: "주", qty: 0 },
        { name: "잔디식재", spec: "들잔디", unit: "m²", qty: 0 },
        { name: "포장공사", spec: "투수블록", unit: "m²", qty: 0 },
        { name: "경계석 설치", spec: "화강석 경계석", unit: "m", qty: 0 },
        { name: "시설물 설치", spec: "벤치·휴지통 등", unit: "개소", qty: 0 },
        { name: "객토 및 정리", spec: "양질토", unit: "m³", qty: 0 }
      ]
    },
    other: {
      name: "기타공사",
      icon: "build",
      desc: "기타 소규모 공사",
      default_items: [
        { name: "공사항목 1", spec: "", unit: "식", qty: 0 },
        { name: "공사항목 2", spec: "", unit: "식", qty: 0 },
        { name: "공사항목 3", spec: "", unit: "식", qty: 0 }
      ]
    }
  }.freeze

  # 간접비 요율
  INDIRECT_RATES = {
    general_expense: { name: "일반관리비", rate: 0.06, basis: "재료비+직접노무비", note: "회계예규 제6조" },
    profit: { name: "이윤", rate: 0.15, basis: "노무비+일반관리비", note: "회계예규 제7조, 상한 15%" },
    industrial_safety: { name: "산업안전보건관리비", rate: 0.018, basis: "재료비+직접노무비", note: "산안법 시행규칙 별표1", threshold: 4000000 },
    industrial_accident: { name: "산재보험료", rate: 0.036, basis: "직접노무비", note: "고시 요율" },
    employment_insurance: { name: "고용보험료", rate: 0.009, basis: "직접노무비", note: "고용보험법" },
    health_pension: { name: "국민건강·연금보험료", rate: 0.089, basis: "직접노무비", note: "4대보험" },
    vat: { name: "부가가치세", rate: 0.10, basis: "합계", note: "부가가치세법" }
  }.freeze

  # 시방서 템플릿
  INSTRUCTION_TEMPLATES = {
    repair: "1. 시공 전 기존 시설물 상태를 사진 촬영하여 기록할 것\n2. 주변 시설물 보양 조치 후 시공에 착수할 것\n3. 철거 폐기물은 관련 법규에 따라 적정 처리할 것\n4. 기존 매설물(배관, 전선 등) 확인 후 시공할 것\n5. 마감재는 승인된 자재만 사용하고, 변경 시 사전 협의할 것\n6. 용접·절단 등 화기작업 시 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)\n7. 화재감시자는 소화기·소화전 위치 확인 및 119 긴급연락체계를 숙지할 것",
    painting: "1. 기존 도막 상태를 확인하고, 불량 부위는 완전히 제거할 것\n2. 우천 시 및 습도 85% 이상에서는 시공을 중지할 것\n3. 도장 간격(재도장 시간)을 제조사 권장 시간 이상 준수할 것\n4. 주변 시설물 및 바닥 보양을 철저히 할 것\n5. 색상은 발주처 승인 후 시공할 것\n6. 도장작업 시 환기를 충분히 하고, 화기 사용 금지 표지판을 게시할 것\n7. 화기작업이 필요한 경우 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)",
    waterproof: "1. 바탕면 건조 상태를 확인 후 시공할 것 (함수율 8% 이하)\n2. 기온 5℃ 이하 또는 35℃ 이상에서는 시공을 중지할 것\n3. 방수층 시공 후 충분한 양생 기간을 확보할 것 (최소 24시간)\n4. 시공 완료 후 담수시험(48시간)을 실시할 것\n5. 배수구, 파라펫 등 취약부위는 보강 시공할 것\n6. 토치작업 등 화기사용 시 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)\n7. 화재감시자는 소화기 비치 및 119 긴급연락체계를 확보할 것",
    electrical: "1. 시공 전 반드시 해당 회로를 차단하고 안전을 확인할 것\n2. 전기설비기술기준 및 내선규정을 준수할 것\n3. 배선은 규정 허용전류 이내로 시공할 것\n4. 접지저항은 규정값 이하로 시공하고 측정 성적서를 제출할 것\n5. 시공 완료 후 절연저항 측정 및 시험 성적서를 제출할 것\n6. 배관 절단 등 화기작업 시 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)\n7. 전기화재 대비 ABC급 소화기를 비치하고 화재감시자는 위치를 숙지할 것",
    plumbing: "1. 기존 배관 상태를 확인하고 단수 조치 후 시공할 것\n2. 배관은 관련 규격(KS) 제품을 사용할 것\n3. 배관 접합부는 누수 시험을 실시할 것\n4. 시공 완료 후 수압시험(1.5배 수압, 60분)을 실시할 것\n5. 보온재는 결로 방지를 위해 이음부 없이 시공할 것\n6. 배관 용접·절단 시 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)\n7. 화재감시자는 소화기·소화전 위치 확인 및 긴급연락체계를 숙지할 것",
    landscape: "1. 식재 시기를 준수할 것 (봄: 3~5월, 가을: 9~11월)\n2. 식재 구덩이는 근원 직경의 3배 이상으로 굴착할 것\n3. 객토 후 충분히 관수하고 지주대를 설치할 것\n4. 포장 시공 전 노반 다짐을 확인할 것 (다짐도 95% 이상)\n5. 하자 보증기간 중 고사목은 동일 수종·규격으로 교체할 것\n6. 용접·절단 등 화기작업 시 화재감시자 1인 이상 배치하고 소화기를 비치할 것",
    other: "1. 시공 전 현장 상태를 사진 촬영하여 기록할 것\n2. 안전 조치를 철저히 하고 시공에 착수할 것\n3. 자재는 승인된 규격품만 사용할 것\n4. 시공 중 문제 발생 시 즉시 감독관에게 보고할 것\n5. 시공 완료 후 현장 정리 및 폐기물 처리를 완료할 것\n6. 용접·절단 등 화기작업 시 화재감시자 1인 이상 배치할 것 (산업안전보건법 시행규칙 제273조)\n7. 화재감시자는 소화기·소화전 위치 및 119 긴급연락체계를 숙지할 것"
  }.freeze

  class << self
    def get_construction_types
      CONSTRUCTION_TYPES.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def get_default_items(type)
      type_sym = type.to_s.to_sym
      return { success: false, error: "유효하지 않은 공사유형입니다." } unless CONSTRUCTION_TYPES.key?(type_sym)

      {
        success: true,
        items: CONSTRUCTION_TYPES[type_sym][:default_items].map.with_index do |item, i|
          item.merge(id: i + 1, unit_price: 0, amount: 0)
        end
      }
    end

    def generate(params)
      type = params[:construction_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 공사유형입니다." } unless CONSTRUCTION_TYPES.key?(type)

      items = parse_items(params[:items])
      info = params[:info] || {}
      custom_instructions = params[:custom_instructions] || ""

      material_cost = items.sum { |i| i[:amount] }
      indirect = calculate_indirect_costs(material_cost)
      total = indirect[:total_with_vat]

      {
        success: true,
        estimate: {
          type_name: CONSTRUCTION_TYPES[type][:name],
          info: info,
          items: items,
          material_cost: material_cost,
          indirect_costs: indirect[:details],
          subtotal: indirect[:subtotal],
          vat: indirect[:vat],
          total: total
        },
        instruction: {
          type_name: CONSTRUCTION_TYPES[type][:name],
          info: info,
          template: INSTRUCTION_TEMPLATES[type],
          custom: custom_instructions,
          total: total
        }
      }
    end

    private

    def parse_items(items_param)
      return [] if items_param.blank?

      items_param.map do |item|
        qty = item[:qty].to_f
        unit_price = item[:unit_price].to_f
        {
          name: item[:name].to_s,
          spec: item[:spec].to_s,
          unit: item[:unit].to_s,
          qty: qty,
          unit_price: unit_price,
          amount: (qty * unit_price).round(0)
        }
      end
    end

    def calculate_indirect_costs(material_cost)
      labor_ratio = 0.4
      labor_cost = (material_cost * labor_ratio).round(0)
      material_only = material_cost - labor_cost

      details = []

      # 일반관리비 = (재료비+직접노무비) × 6%
      general = ((material_only + labor_cost) * INDIRECT_RATES[:general_expense][:rate]).round(0)
      details << { name: "일반관리비", amount: general, note: "#{(INDIRECT_RATES[:general_expense][:rate] * 100).round(0)}%" }

      # 이윤 = (노무비+일반관리비) × 15%
      profit = ((labor_cost + general) * INDIRECT_RATES[:profit][:rate]).round(0)
      details << { name: "이윤", amount: profit, note: "상한 #{(INDIRECT_RATES[:profit][:rate] * 100).round(0)}%" }

      # 산재보험 등 4대보험
      insurance = (labor_cost * (INDIRECT_RATES[:industrial_accident][:rate] + INDIRECT_RATES[:employment_insurance][:rate] + INDIRECT_RATES[:health_pension][:rate])).round(0)
      details << { name: "보험료(산재·고용·건강·연금)", amount: insurance, note: "노무비 기준" }

      # 산업안전보건관리비 (400만원 이상)
      safety = 0
      if material_cost >= INDIRECT_RATES[:industrial_safety][:threshold]
        safety = ((material_only + labor_cost) * INDIRECT_RATES[:industrial_safety][:rate]).round(0)
        details << { name: "산업안전보건관리비", amount: safety, note: "#{(INDIRECT_RATES[:industrial_safety][:rate] * 100).round(1)}%" }
      end

      subtotal = material_cost + general + profit + insurance + safety
      vat = (subtotal * INDIRECT_RATES[:vat][:rate]).round(0)

      {
        details: details,
        subtotal: subtotal,
        vat: vat,
        total_with_vat: subtotal + vat
      }
    end
  end
end
