# 계약서류 생성 서비스
# 물품/용역/공사별 필수 계약서류를 자동 생성하는 서비스
# 법령 근거 및 주의사항 포함

class ContractDocumentService
  # 계약 유형별 필수 서류 목록 (법령 근거 및 주의사항 포함)
  CONTRACT_DOCUMENTS = {
    goods: {
      name: "물품",
      documents: {
        # 계약 전
        pre_contract: [
          {
            id: "restriction_check", name: "수의계약 체결 제한 여부 확인서", required: true,
            description: "배제사유 확인",
            legal_basis: "지방계약법 시행령 제25조, 제31조",
            caution: "계약상대자가 부정당업자 제재, 영업정지 등 배제사유에 해당하는지 반드시 확인",
            tip: "나라장터(G2B) 부정당업자 제재현황 조회 후 확인서 징구"
          },
          {
            id: "specification", name: "물품 규격서(Specification)", required: true,
            description: "물품 규격 명시",
            legal_basis: "지방계약법 시행령 제14조",
            caution: "특정 업체에 유리한 규격 설정 금지. 용도에 맞는 최소 규격 설정",
            tip: "규격서에 필수 사양과 선택 사양을 구분하여 기재"
          },
          {
            id: "estimate_request", name: "견적요청서", required: true,
            description: "2인 이상 견적 요청",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "2,000만원 초과 시 2인 이상 견적 필수. 2천만원 초과 시 G2B 전자견적 의무",
            tip: "견적 요청 시 규격서, 수량, 납품기한을 명확히 기재"
          },
          {
            id: "estimate", name: "견적서", required: true,
            description: "업체별 견적서",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "견적서 유효기간 및 부가세 포함 여부 확인",
            tip: "견적서에 업체 인감(직인) 날인 여부와 유효기간을 반드시 확인"
          },
          {
            id: "price_comparison", name: "가격비교표", required: true,
            description: "견적 비교표",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "최저가 선정 사유 명시 필요",
            tip: "동일 규격 기준으로 비교, 배송비 등 부대비용 포함"
          },
          {
            id: "predicted_price", name: "예정가격조서", required: false,
            description: "예정가격 산정 (2천만원 이하 생략 가능)",
            legal_basis: "지방계약법 시행령 제7조~제9조",
            caution: "추정가격 2천만원 이하 수의계약 시 예정가격 작성 생략 가능 (시행령 제9조)",
            tip: "거래실례가격, 원가계산가격 등 적정 방법으로 산정"
          },
          {
            id: "budget_request", name: "예산배정요청서", required: false,
            description: "예산 미배정 시",
            legal_basis: "지방재정법 제44조",
            caution: "예산 배정 전 계약 체결 불가",
            tip: "예산과목, 금액, 사업명 정확히 기재"
          }
        ],
        # 계약 체결
        contract: [
          {
            id: "contract_form", name: "물품구매 표준계약서", required: true,
            description: "계약서 본문",
            legal_basis: "지방계약법 제14조, 시행령 제49조",
            caution: "계약금액 5,000만원 초과 시 계약서 작성 의무 (시행령 제50조)",
            tip: "계약서 특수조건에 납품지연 지체상금 조항 포함"
          },
          {
            id: "oath", name: "수의계약 통합서약서", required: true,
            description: "청렴계약, 담합방지 등",
            legal_basis: "지방계약법 시행령 제25조, 계약집행기준",
            caution: "수의계약 사유에 해당하는지 반드시 확인",
            tip: "부정당업자 제재 조항 고지 필수"
          },
          {
            id: "business_registration", name: "사업자등록증 사본", required: true,
            description: "계약 상대방",
            legal_basis: "지방계약법 시행령 제13조",
            caution: "휴·폐업 여부 국세청에서 확인 필요",
            tip: "계약 직전 발급본 징구 권장"
          },
          {
            id: "seal_certificate", name: "인감증명서", required: true,
            description: "또는 본인서명사실확인서",
            legal_basis: "지방계약법 제14조, 시행령 제49조",
            caution: "발급일로부터 3개월 이내 서류만 유효",
            tip: "법인인 경우 법인인감증명서, 대표자 확인"
          },
          {
            id: "contract_guarantee", name: "계약보증서", required: false,
            description: "계약금액 10% 이상 시",
            legal_basis: "지방계약법 시행령 제53조",
            caution: "5,000만원 이하 시 계약보증금 면제 가능",
            tip: "보증보험증권, 정기예금증서 등으로 납부 가능"
          }
        ],
        # 납품/검수
        delivery: [
          {
            id: "delivery_report", name: "납품서", required: true,
            description: "물품 납품 시",
            legal_basis: "공유재산 및 물품 관리법 제65조",
            caution: "납품서에 물품명, 규격, 수량 정확히 기재",
            tip: "납품 시 담당자 입회 하에 수량 확인"
          },
          {
            id: "inspection_report", name: "검사검수조서", required: true,
            description: "물품 검수 확인",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "납품일로부터 14일 이내 검사 완료",
            tip: "계약서 규격과 일치 여부 꼼꼼히 확인"
          },
          {
            id: "delivery_confirmation", name: "납품확인서", required: true,
            description: "납품 완료 확인",
            legal_basis: "지방계약법 시행령 제65조",
            caution: "검사조서 작성 후 발급",
            tip: "물품대장 등재 후 확인서 발급"
          }
        ],
        # 대금 지급
        payment: [
          {
            id: "invoice", name: "대금청구서", required: true,
            description: "세금계산서 포함",
            legal_basis: "지방계약법 제18조",
            caution: "세금계산서 발행일과 검수일 일치 확인",
            tip: "전자세금계산서 발행 여부 확인"
          },
          {
            id: "payment_request", name: "지출결의서", required: true,
            description: "대금 지급 기안",
            legal_basis: "지방회계법 제29조",
            caution: "검수 완료 후 대금 청구 가능",
            tip: "지급기한: 청구일로부터 5일 이내 (시행령 제67조, 지연 시 이자 발생)"
          }
        ]
      }
    },
    service: {
      name: "용역",
      documents: {
        pre_contract: [
          {
            id: "restriction_check", name: "수의계약 체결 제한 여부 확인서", required: true,
            description: "배제사유 확인",
            legal_basis: "지방계약법 시행령 제25조, 제31조",
            caution: "계약상대자가 부정당업자 제재, 영업정지 등 배제사유에 해당하는지 반드시 확인",
            tip: "나라장터(G2B) 부정당업자 제재현황 조회 후 확인서 징구"
          },
          {
            id: "estimate_request", name: "견적요청서", required: true,
            description: "2인 이상 견적 요청",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "용역 범위와 기간을 명확히 제시. 2천만원 초과 시 G2B 전자견적 의무",
            tip: "과업지시서 초안과 함께 견적 요청"
          },
          {
            id: "estimate", name: "견적서", required: true,
            description: "업체별 견적서",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "인건비, 경비 등 항목별 금액 확인",
            tip: "견적서에 업체 인감(직인) 날인 여부와 유효기간을 반드시 확인"
          },
          {
            id: "task_specification", name: "과업지시서", required: true,
            description: "용역 범위 및 내용",
            legal_basis: "지방계약법 시행령 제8조, 계약집행기준",
            caution: "과업 내용, 범위, 성과품 목록 구체적 명시",
            tip: "과업 변경 시 계약변경 근거 조항 포함"
          },
          {
            id: "price_comparison", name: "가격비교표", required: true,
            description: "견적 비교표",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "용역 특성상 가격 외 기술력도 검토",
            tip: "필요시 기술능력평가 병행 검토"
          },
          {
            id: "predicted_price", name: "예정가격조서", required: false,
            description: "예정가격 산정 (2천만원 이하 생략 가능)",
            legal_basis: "지방계약법 시행령 제7조~제9조",
            caution: "추정가격 2천만원 이하 수의계약 시 예정가격 작성 생략 가능 (시행령 제9조)",
            tip: "원가계산 시 노임단가, 제경비 등 적정성 검토"
          }
        ],
        contract: [
          {
            id: "contract_form", name: "용역 표준계약서", required: true,
            description: "계약서 본문",
            legal_basis: "지방계약법 제14조, 시행령 제49조",
            caution: "과업지시서를 계약서 별첨으로 포함",
            tip: "지식재산권 귀속 조항 확인 필수"
          },
          {
            id: "oath", name: "수의계약 통합서약서", required: true,
            description: "청렴계약, 담합방지 등",
            legal_basis: "지방계약법 시행령 제25조, 계약집행기준",
            caution: "용역 수의계약 사유 해당 여부 검토",
            tip: "특수용역의 경우 특수조건 고지"
          },
          {
            id: "business_registration", name: "사업자등록증 사본", required: true,
            description: "계약 상대방",
            legal_basis: "지방계약법 시행령 제13조",
            caution: "용역 수행 가능 업종 여부 확인",
            tip: "해당 용역 관련 면허·자격 보유 여부 확인"
          },
          {
            id: "seal_certificate", name: "인감증명서", required: true,
            description: "또는 본인서명사실확인서",
            legal_basis: "지방계약법 제14조, 시행령 제49조",
            caution: "발급일로부터 3개월 이내 서류만 유효",
            tip: "법인인 경우 법인인감증명서 확인"
          },
          {
            id: "performance_guarantee", name: "계약이행보증서", required: false,
            description: "계약금액 10% 이상",
            legal_basis: "지방계약법 시행령 제53조",
            caution: "용역 미이행 시 보증금 귀속",
            tip: "계약이행보증보험증권으로 대체 가능"
          },
          {
            id: "defect_guarantee", name: "하자보증서", required: false,
            description: "필요 시",
            legal_basis: "지방계약법 시행령 제69조, 제71조",
            caution: "하자담보책임기간 용역 특성에 맞게 설정",
            tip: "SW개발 용역: 통상 1년, 유지보수: 해당 없음"
          }
        ],
        execution: [
          {
            id: "start_report", name: "착수계", required: true,
            description: "용역 착수 신고",
            legal_basis: "지방계약법 제16조, 계약집행기준",
            caution: "착수일로부터 용역기간 기산",
            tip: "착수계와 함께 세부 추진계획서 제출 요청"
          },
          {
            id: "personnel_list", name: "투입인력 명단", required: true,
            description: "용역 투입 인력",
            legal_basis: "과업지시서, 계약집행기준",
            caution: "제안서 인력과 실제 투입인력 일치 확인",
            tip: "인력 변경 시 사전 승인 절차 안내"
          },
          {
            id: "progress_report", name: "진행상황보고서", required: false,
            description: "중간 보고",
            legal_basis: "계약서 특수조건",
            caution: "계약서에 명시된 보고 주기 준수",
            tip: "중간점검회의 개최하여 진도율 확인"
          }
        ],
        completion: [
          {
            id: "completion_report", name: "준공계", required: true,
            description: "용역 완료 신고",
            legal_basis: "지방계약법 제17조, 시행령 제64조",
            caution: "준공기한 내 제출 여부 확인",
            tip: "성과품 목록과 함께 제출"
          },
          {
            id: "inspection_report", name: "검사검수조서", required: true,
            description: "용역 결과 검수",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "과업지시서 기준 성과품 검수",
            tip: "필요시 전문가 검수 의뢰 가능"
          },
          {
            id: "deliverables", name: "성과품 목록", required: true,
            description: "납품 산출물",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "과업지시서 성과품과 일치 확인",
            tip: "전자파일 및 인쇄물 각각 수량 확인"
          },
          {
            id: "labor_payment", name: "노무비 지급확인서", required: false,
            description: "건설근로자 해당 시",
            legal_basis: "건설산업기본법 제34조",
            caution: "건설관련 용역(설계·감리)은 해당될 수 있음",
            tip: "건설근로자 고용 시에만 해당"
          }
        ],
        payment: [
          {
            id: "invoice", name: "대금청구서", required: true,
            description: "세금계산서 포함",
            legal_basis: "지방계약법 제18조",
            caution: "기성금 청구 시 기성검사 선행 필요",
            tip: "선금 지급 시 선금급 지급비율 확인"
          },
          {
            id: "payment_request", name: "지출결의서", required: true,
            description: "대금 지급 기안",
            legal_basis: "지방회계법 제29조",
            caution: "검수 완료 후 대금 지급 가능",
            tip: "지급기한: 청구일로부터 5일 이내 (시행령 제67조)"
          }
        ]
      }
    },
    construction: {
      name: "공사",
      documents: {
        pre_contract: [
          {
            id: "restriction_check", name: "수의계약 체결 제한 여부 확인서", required: true,
            description: "배제사유 확인",
            legal_basis: "지방계약법 시행령 제25조, 제31조",
            caution: "계약상대자가 부정당업자 제재, 영업정지 등 배제사유에 해당하는지 반드시 확인",
            tip: "나라장터(G2B) 부정당업자 제재현황 조회 후 확인서 징구"
          },
          {
            id: "design_document", name: "설계서", required: true,
            description: "설계도면, 내역서 등",
            legal_basis: "지방계약법 시행령 제8조, 제15조, 건설기술진흥법 제48조",
            caution: "설계도서: 도면, 시방서, 내역서, 현장설명서 포함",
            tip: "설계VE 및 기술자문 검토 권장"
          },
          {
            id: "estimate_request", name: "견적요청서", required: true,
            description: "2인 이상 견적 요청",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "공사 규모에 맞는 업체 자격요건 확인. 2천만원 초과 시 G2B 전자견적 의무",
            tip: "설계서 및 현장설명 자료 함께 제공"
          },
          {
            id: "estimate", name: "견적서", required: true,
            description: "업체별 견적서",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "내역서 기준 견적 산출 여부 확인",
            tip: "견적서에 업체 인감(직인) 날인 여부와 유효기간을 반드시 확인"
          },
          {
            id: "price_comparison", name: "가격비교표", required: true,
            description: "견적 비교표",
            legal_basis: "지방계약법 시행령 제30조",
            caution: "공사 적격업체 선정 사유 명확히 기재",
            tip: "시공실적, 기술능력 함께 검토"
          },
          {
            id: "predicted_price", name: "예정가격조서", required: true,
            description: "예정가격 산정 (2천만원 이하 생략 가능)",
            legal_basis: "지방계약법 시행령 제8조, 제9조",
            caution: "추정가격 2천만원 이하 수의계약 시 예정가격 작성 생략 가능 (시행령 제9조)",
            tip: "표준품셈, 실적공사비 활용"
          }
        ],
        contract: [
          {
            id: "contract_form", name: "공사 표준계약서", required: true,
            description: "계약서 본문",
            legal_basis: "지방계약법 제14조, 건설산업기본법 제22조",
            caution: "계약서 특수조건에 안전관리비, 환경관리비 명시",
            tip: "공사계약일반조건 및 특수조건 첨부"
          },
          {
            id: "oath", name: "수의계약 통합서약서", required: true,
            description: "청렴계약, 담합방지 등",
            legal_basis: "지방계약법 시행령 제25조, 계약집행기준",
            caution: "건설공사 수의계약 가능 금액 기준 확인",
            tip: "공사 규모별 수의계약 한도액 상이"
          },
          {
            id: "business_registration", name: "사업자등록증 사본", required: true,
            description: "계약 상대방",
            legal_basis: "지방계약법 시행령 제13조",
            caution: "휴·폐업 여부 확인",
            tip: "건설업 등록 업종과 일치 확인"
          },
          {
            id: "license", name: "건설업 등록증 사본", required: true,
            description: "해당 업종",
            legal_basis: "건설산업기본법 제9조",
            caution: "해당 공종에 적합한 업종 등록 확인",
            tip: "면허수첩으로 시공능력 확인 가능"
          },
          {
            id: "seal_certificate", name: "인감증명서", required: true,
            description: "또는 본인서명사실확인서",
            legal_basis: "지방계약법 제14조, 시행령 제49조",
            caution: "발급일로부터 3개월 이내",
            tip: "법인의 경우 법인인감증명서"
          },
          {
            id: "contract_guarantee", name: "계약보증서", required: true,
            description: "계약금액 10% 이상",
            legal_basis: "지방계약법 시행령 제53조",
            caution: "공사계약 시 계약보증금 필수",
            tip: "공사이행보증서로 대체 가능 (연대보증 포함)"
          },
          {
            id: "performance_guarantee", name: "계약이행보증서", required: true,
            description: "계약금액 10%",
            legal_basis: "지방계약법 시행령 제53조, 건설산업기본법 제34조",
            caution: "선금 지급 시 선금이행보증서 별도 징구",
            tip: "보증기관: 건설공제조합, 보증보험사 등"
          },
          {
            id: "defect_guarantee", name: "하자보증서", required: true,
            description: "공종별 하자보증",
            legal_basis: "지방계약법 시행령 제69조, 제71조",
            caution: "공종별 하자담보책임기간 상이 (2~10년)",
            tip: "시설물법 적용 시설은 10년까지"
          },
          {
            id: "insurance", name: "보험가입증명서", required: true,
            description: "산재, 고용보험 등",
            legal_basis: "건설산업기본법 제34조, 산업안전보건법 제72조",
            caution: "4대 보험 + 건설공사보험 가입 확인",
            tip: "산재·고용보험 현장적용 신고 확인"
          }
        ],
        execution: [
          {
            id: "start_report", name: "착공계", required: true,
            description: "공사 착공 신고",
            legal_basis: "건설산업기본법 제28조, 지방계약법 제16조",
            caution: "착공 전 안전관리계획서 승인 필요",
            tip: "현장대리인 지정 신고서와 함께 제출"
          },
          {
            id: "safety_plan", name: "안전관리계획서", required: true,
            description: "현장 안전관리",
            legal_basis: "건설기술진흥법 제62조, 산업안전보건법 제42조",
            caution: "시설물안전법 대상 구조물 또는 건설기술진흥법령 기준 해당 시 필수",
            tip: "안전관리비 사용계획 포함"
          },
          {
            id: "safety_checklist", name: "안전점검 체크리스트", required: true,
            description: "정기 안전점검",
            legal_basis: "산업안전보건법 제36조",
            caution: "일일, 주간, 월간 안전점검 실시",
            tip: "위험요소 발견 시 즉시 시정조치"
          },
          {
            id: "construction_log", name: "공사감독일지", required: true,
            description: "감독 업무 기록",
            legal_basis: "지방계약법 제16조, 시행령 제60조",
            caution: "감독관은 매일 현장 확인 및 기록",
            tip: "기상, 인력, 장비, 작업내용 상세 기록"
          },
          {
            id: "progress_payment", name: "기성검사원", required: false,
            description: "기성금 청구 시",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "기성부분 검사 후 기성금 지급",
            tip: "월별 또는 공정률 기준 기성 지급"
          },
          {
            id: "design_change", name: "설계변경요청서", required: false,
            description: "설계변경 시",
            legal_basis: "지방계약법 시행령 제65조, 제66조",
            caution: "설계변경 사유: 현장여건 상이, 물가변동 등",
            tip: "설계변경 전 반드시 승인 후 시공"
          }
        ],
        completion: [
          {
            id: "completion_report", name: "준공계", required: true,
            description: "공사 완료 신고",
            legal_basis: "지방계약법 제17조, 시행령 제64조, 건설산업기본법 제28조",
            caution: "준공기한 내 준공계 제출",
            tip: "준공도면, 사진 등 준공자료 함께 제출"
          },
          {
            id: "inspection_report", name: "준공검사조서", required: true,
            description: "공사 준공 검사",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "준공계 제출 후 14일 이내 검사",
            tip: "하자사항 발견 시 보완 후 재검사"
          },
          {
            id: "as_built", name: "준공도면", required: true,
            description: "준공 후 도면",
            legal_basis: "건설기술진흥법 제55조",
            caution: "설계변경 사항 반영된 최종도면",
            tip: "시설물 유지관리에 필수 자료"
          },
          {
            id: "quality_test", name: "품질시험성과표", required: false,
            description: "품질시험 결과",
            legal_basis: "건설기술진흥법 제55조",
            caution: "품질시험계획서 대비 실적 확인",
            tip: "콘크리트, 철근, 지반 등 주요 시험"
          },
          {
            id: "photo_report", name: "공사사진첩", required: true,
            description: "착공~준공 사진",
            legal_basis: "지방계약법 시행령 제64조",
            caution: "착공 전-중-후 사진 비교 가능하게 정리",
            tip: "위치, 날짜, 공종 표시"
          },
          {
            id: "labor_payment", name: "노무비 지급확인서", required: true,
            description: "건설근로자",
            legal_basis: "건설산업기본법 제34조, 제68조의3",
            caution: "건설근로자 임금 체불 방지 의무",
            tip: "노무비 구분관리 및 지급 확인"
          },
          {
            id: "subcontract_payment", name: "하도급대금 직접지급확인서", required: false,
            description: "하도급 시",
            legal_basis: "하도급거래 공정화에 관한 법률 제14조",
            caution: "하도급 대금 직접 지급 요건 확인",
            tip: "하수급인 요청 시 직접 지급 의무"
          }
        ],
        payment: [
          {
            id: "invoice", name: "대금청구서", required: true,
            description: "세금계산서 포함",
            legal_basis: "지방계약법 제18조",
            caution: "준공검사 합격 후 대금 청구 가능",
            tip: "하자보증금 공제 후 지급"
          },
          {
            id: "payment_request", name: "지출결의서", required: true,
            description: "대금 지급 기안",
            legal_basis: "지방회계법 제29조",
            caution: "대금지급 지연 시 연체이자 발생",
            tip: "지급기한: 청구일로부터 5일 이내 (시행령 제67조)"
          }
        ]
      }
    }
  }.freeze

  # 단계 정보
  STAGES = {
    pre_contract: { name: "계약 전 단계", icon: "edit_document", order: 1 },
    contract: { name: "계약 체결", icon: "handshake", order: 2 },
    execution: { name: "이행 단계", icon: "engineering", order: 3 },
    delivery: { name: "납품/검수", icon: "local_shipping", order: 4 },
    completion: { name: "완료 단계", icon: "task_alt", order: 5 },
    payment: { name: "대금 지급", icon: "payments", order: 6 }
  }.freeze

  class << self
    # 계약 유형별 서류 목록 조회
    def get_documents_for_type(contract_type)
      type_sym = contract_type.to_sym
      return nil unless CONTRACT_DOCUMENTS[type_sym]

      type_data = CONTRACT_DOCUMENTS[type_sym]
      documents_by_stage = {}

      type_data[:documents].each do |stage, docs|
        stage_info = STAGES[stage]
        documents_by_stage[stage] = {
          name: stage_info[:name],
          icon: stage_info[:icon],
          order: stage_info[:order],
          documents: docs
        }
      end

      {
        type: type_sym,
        name: type_data[:name],
        stages: documents_by_stage.sort_by { |_, v| v[:order] }.to_h
      }
    end

    # 모든 계약 유형 목록
    def get_all_types
      CONTRACT_DOCUMENTS.map do |key, value|
        { id: key, name: value[:name] }
      end
    end

    # 체크리스트 생성 (선택된 서류 기준)
    def generate_checklist(contract_type:, contract_info:, selected_documents: nil)
      type_data = get_documents_for_type(contract_type)
      return { success: false, error: "유효하지 않은 계약 유형입니다." } unless type_data

      checklist = {
        contract_info: contract_info,
        contract_type: type_data[:name],
        generated_at: Time.current.strftime("%Y-%m-%d %H:%M"),
        stages: []
      }

      type_data[:stages].each do |stage_key, stage_data|
        stage_checklist = {
          stage: stage_data[:name],
          icon: stage_data[:icon],
          documents: []
        }

        stage_data[:documents].each do |doc|
          # 선택된 서류만 포함하거나, 필수 서류는 항상 포함
          if selected_documents.nil? || selected_documents.include?(doc[:id]) || doc[:required]
            stage_checklist[:documents] << {
              id: doc[:id],
              name: doc[:name],
              description: doc[:description],
              required: doc[:required],
              checked: false
            }
          end
        end

        checklist[:stages] << stage_checklist if stage_checklist[:documents].any?
      end

      { success: true, checklist: checklist }
    end

    # 서류 통계
    def get_document_stats(contract_type)
      type_data = get_documents_for_type(contract_type)
      return nil unless type_data

      total = 0
      required = 0

      type_data[:stages].each do |_, stage_data|
        stage_data[:documents].each do |doc|
          total += 1
          required += 1 if doc[:required]
        end
      end

      { total: total, required: required, optional: total - required }
    end
  end
end
