# 기성검사 체크리스트 서비스
# 공사 유형별 기성검사 항목 자동 생성
class ProgressInspectionService
  # 공사유형별 검사항목
  INSPECTION_TYPES = {
    general_building: {
      name: "일반건축",
      icon: "apartment",
      desc: "건축·토목 공사"
    },
    small_repair: {
      name: "소규모 수선",
      icon: "home_repair_service",
      desc: "시설물 보수·수선"
    },
    electrical: {
      name: "전기공사",
      icon: "electrical_services",
      desc: "전기·조명·통신"
    },
    plumbing: {
      name: "설비공사",
      icon: "plumbing",
      desc: "급배수·냉난방"
    },
    painting: {
      name: "도장공사",
      icon: "format_paint",
      desc: "내외부 도장"
    },
    waterproof: {
      name: "방수공사",
      icon: "water_drop",
      desc: "옥상·지하 방수"
    },
    landscape: {
      name: "조경공사",
      icon: "park",
      desc: "식재·포장·시설물"
    }
  }.freeze

  # 카테고리별 검사항목
  INSPECTION_ITEMS = {
    general_building: {
      quality: [
        { item: "시공이 설계도서(도면·시방서)대로 시행되었는가", critical: true },
        { item: "사용자재가 승인된 자재와 일치하는가", critical: true },
        { item: "자재 시험성적서가 제출되었는가", critical: false },
        { item: "콘크리트 압축강도 시험결과가 기준 이상인가", critical: true },
        { item: "철근 배근이 설계도면대로 시공되었는가", critical: true },
        { item: "마감재 시공 상태가 양호한가 (균열·들뜸·변색 등)", critical: false },
        { item: "방수·단열 시공이 적정한가", critical: false }
      ],
      safety: [
        { item: "안전관리비가 목적대로 사용되었는가", critical: true },
        { item: "현장 안전시설물(가설울타리, 표지판 등)이 설치되어 있는가", critical: false },
        { item: "안전보호구 착용 상태가 양호한가", critical: false },
        { item: "위험물 관리가 적정한가", critical: false }
      ],
      documents: [
        { item: "시공상세도면이 승인·관리되고 있는가", critical: false },
        { item: "품질시험 성적서가 구비되어 있는가", critical: true },
        { item: "자재검수 기록이 작성되어 있는가", critical: false },
        { item: "공사일보가 작성되어 있는가", critical: false },
        { item: "기성부분 내역서가 작성되었는가", critical: true },
        { item: "기성사진첩이 준비되어 있는가", critical: true }
      ],
      progress: [
        { item: "공정률이 기성신청 내용과 부합하는가", critical: true },
        { item: "공정계획 대비 실적이 적정한가", critical: false },
        { item: "기성부분 수량이 실측과 일치하는가", critical: true },
        { item: "부진 공정에 대한 만회대책이 있는가", critical: false }
      ]
    },
    small_repair: {
      quality: [
        { item: "시공이 내역서대로 시행되었는가", critical: true },
        { item: "사용자재가 견적 시 제시한 자재와 동일한가", critical: true },
        { item: "마감 상태가 양호한가 (들뜸·변색·하자 등)", critical: false },
        { item: "기존 시설물과의 접합부 처리가 양호한가", critical: false }
      ],
      safety: [
        { item: "작업 중 안전조치가 이루어졌는가", critical: false },
        { item: "주변 시설물 보호 조치가 되어 있는가", critical: false }
      ],
      documents: [
        { item: "시공 전·후 사진이 촬영되었는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true },
        { item: "자재 납품서 또는 영수증이 있는가", critical: false }
      ],
      progress: [
        { item: "공사가 완료되었는가 (또는 기성부분이 확인되는가)", critical: true },
        { item: "시공 수량이 내역서와 일치하는가", critical: true }
      ]
    },
    electrical: {
      quality: [
        { item: "배선이 내선규정에 맞게 시공되었는가", critical: true },
        { item: "접지저항이 규정값 이하인가", critical: true },
        { item: "절연저항 측정값이 기준 이상인가", critical: true },
        { item: "분전반 설치 및 회로 구성이 적정한가", critical: false },
        { item: "조명기구 설치 및 점등 상태가 양호한가", critical: false },
        { item: "전선관 시공 상태가 양호한가", critical: false }
      ],
      safety: [
        { item: "활선 작업 시 안전조치가 되었는가", critical: true },
        { item: "접지공사가 완료되었는가", critical: true }
      ],
      documents: [
        { item: "절연저항 측정 성적서가 있는가", critical: true },
        { item: "접지저항 측정 성적서가 있는가", critical: true },
        { item: "자재 시험성적서가 있는가 (KS 인증 등)", critical: false },
        { item: "시공사진이 촬영되었는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true }
      ],
      progress: [
        { item: "시공 수량이 내역서와 일치하는가", critical: true },
        { item: "공정률이 기성신청과 부합하는가", critical: true }
      ]
    },
    plumbing: {
      quality: [
        { item: "배관 시공이 설계도면대로 되었는가", critical: true },
        { item: "수압시험 결과가 적정한가 (1.5배, 60분)", critical: true },
        { item: "위생기구 설치 상태가 양호한가", critical: false },
        { item: "배관 보온 시공이 적정한가", critical: false },
        { item: "배수 구배가 적정한가", critical: false }
      ],
      safety: [
        { item: "가스 관련 작업 시 안전조치가 되었는가", critical: true },
        { item: "용접 작업 시 소화기 비치 등 안전조치가 되었는가", critical: false }
      ],
      documents: [
        { item: "수압시험 성적서가 있는가", critical: true },
        { item: "배관재 시험성적서가 있는가", critical: false },
        { item: "시공사진이 촬영되었는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true }
      ],
      progress: [
        { item: "시공 수량이 내역서와 일치하는가", critical: true },
        { item: "공정률이 기성신청과 부합하는가", critical: true }
      ]
    },
    painting: {
      quality: [
        { item: "바탕처리가 적정하게 되었는가 (퍼티·프라이머)", critical: true },
        { item: "도장 횟수가 시방서대로 시공되었는가", critical: true },
        { item: "도막 두께가 적정한가", critical: false },
        { item: "색상이 승인된 색상과 일치하는가", critical: false },
        { item: "도막 상태가 양호한가 (처짐·기포·갈라짐 등)", critical: false }
      ],
      safety: [
        { item: "환기 조치가 적정하게 되었는가", critical: false },
        { item: "도료 보관 및 관리가 적정한가 (화기 주의)", critical: false }
      ],
      documents: [
        { item: "도료 자재 성적서가 있는가", critical: false },
        { item: "시공사진 (바탕처리·하도·중도·상도)이 있는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true }
      ],
      progress: [
        { item: "시공 면적이 내역서와 일치하는가", critical: true },
        { item: "공정률이 기성신청과 부합하는가", critical: true }
      ]
    },
    waterproof: {
      quality: [
        { item: "바탕면 건조 상태가 확인되었는가 (함수율 8% 이하)", critical: true },
        { item: "프라이머 도포가 적정한가", critical: false },
        { item: "방수층 두께가 시방서 기준 이상인가", critical: true },
        { item: "이음부·겹침부 처리가 적정한가", critical: true },
        { item: "담수시험(48시간) 결과가 적정한가", critical: true },
        { item: "보호층 시공이 적정한가", critical: false }
      ],
      safety: [
        { item: "옥상 작업 시 추락방지 안전조치가 되었는가", critical: true },
        { item: "유기용제 사용 시 환기 조치가 되었는가", critical: false }
      ],
      documents: [
        { item: "방수자재 시험성적서가 있는가", critical: true },
        { item: "담수시험 결과서가 있는가", critical: true },
        { item: "시공사진 (각 공정별)이 있는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true }
      ],
      progress: [
        { item: "시공 면적이 내역서와 일치하는가", critical: true },
        { item: "공정률이 기성신청과 부합하는가", critical: true }
      ]
    },
    landscape: {
      quality: [
        { item: "식재 수종·규격이 설계와 일치하는가", critical: true },
        { item: "식재 방법이 적정한가 (구덩이·객토·관수)", critical: false },
        { item: "지주대 설치가 적정한가", critical: false },
        { item: "포장 시공 상태가 양호한가", critical: false },
        { item: "배수시설이 적정하게 설치되었는가", critical: false }
      ],
      safety: [
        { item: "중장비 작업 시 안전조치가 되었는가", critical: false },
        { item: "보행자 안전 조치가 되었는가", critical: false }
      ],
      documents: [
        { item: "수목 규격 확인서(수고·흉고직경 등)가 있는가", critical: true },
        { item: "수목 반입 사진이 있는가", critical: true },
        { item: "시공사진이 촬영되었는가", critical: true },
        { item: "기성내역서가 작성되었는가", critical: true }
      ],
      progress: [
        { item: "식재 수량이 내역서와 일치하는가", critical: true },
        { item: "공정률이 기성신청과 부합하는가", critical: true }
      ]
    }
  }.freeze

  # 법적 근거
  LEGAL_REFERENCES = [
    { law: "지방계약법 시행령 제64조", content: "검사는 계약서·설계서 등에 따라 이행 여부를 확인" },
    { law: "지방계약법 시행령 제65조", content: "기성부분에 대하여 검사 후 대가를 지급" },
    { law: "지방계약법 시행령 제67조", content: "검사 완료 후 5일 이내에 대금 지급" },
    { law: "지방계약법 시행령 제68조", content: "기성검사 시 감독관의 확인을 받아야 함" }
  ].freeze

  CATEGORY_NAMES = {
    quality: "품질관리",
    safety: "안전관리",
    documents: "서류관리",
    progress: "공정관리"
  }.freeze

  CATEGORY_ICONS = {
    quality: "verified",
    safety: "health_and_safety",
    documents: "folder_open",
    progress: "timeline"
  }.freeze

  class << self
    def get_inspection_types
      INSPECTION_TYPES.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def generate(params)
      type = params[:inspection_type].to_s.to_sym
      return { success: false, error: "유효하지 않은 공사유형입니다." } unless INSPECTION_ITEMS.key?(type)

      items = INSPECTION_ITEMS[type]
      categories = items.map do |cat_key, cat_items|
        {
          key: cat_key.to_s,
          name: CATEGORY_NAMES[cat_key],
          icon: CATEGORY_ICONS[cat_key],
          items: cat_items
        }
      end

      {
        success: true,
        checklist: {
          type_name: INSPECTION_TYPES[type][:name],
          contract_info: {
            name: params[:contract_name].to_s,
            amount: params[:contract_amount].to_s,
            contractor: params[:contractor].to_s,
            contract_date: params[:contract_date].to_s,
            completion_date: params[:completion_date].to_s
          },
          inspection_info: {
            round: params[:round].to_s,
            period: params[:inspection_period].to_s,
            amount: params[:inspection_amount].to_s,
            paid: params[:paid_amount].to_s
          },
          categories: categories,
          legal_references: LEGAL_REFERENCES
        }
      }
    end
  end
end
