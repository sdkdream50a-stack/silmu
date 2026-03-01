# 공공조달관리사 표준교재 4권 기반 커리큘럼 데이터
# 한국조달연구원 공공조달관리사 표준교재 (2026.01 기준)
module ExamCurriculum
  SUBJECTS = [
    # ────────────────────────────────────────────────────────────
    # 1권: 공공조달의 이해 — 공공조달 및 법제도 일반
    # ────────────────────────────────────────────────────────────
    {
      id: 1,
      number: "1권",
      title: "공공조달의 이해",
      subtitle: "공공조달 및 법제도 일반",
      color: "emerald",
      icon: "public",
      total_chapters: 7,
      chapters: [
        {
          number: 1,
          title: "공공조달 개요",
          sections: [
            "공공조달의 정의 및 목적",
            "공공조달 참여자, 이해관계자",
            "공공조달의 특성",
            "공공조달의 구성 체계"
          ],
          learning_objectives: [
            "공공조달 역사적 발전 과정을 통한 공공조달 정의",
            "공공조달의 중요성을 설명",
            "공공조달 참여자와 이해관계자를 설명",
            "공공조달과 민간조달(구매)의 특성과 차이점을 설명",
            "공공조달 프로세스가 순환적이고 연속적인 이유 이해",
            "공공조달의 구성체계에 따른 공공조달 실행 및 관리 차이점 설명"
          ],
          keywords: [
            "공공조달(Public procurement)",
            "공공조달 특성(Public Procurement Characteristics)",
            "민간조달(Private procurement)",
            "구매(Purchasing)",
            "공공조달 성숙 단계(Public procurement Process)",
            "공공조달 구성 체계(Public Procurement Framework)"
          ],
          exam_points: [
            "VFM(Value For Money): 경쟁을 통해 최적 공급자 선정 — 핵심 원칙",
            "OECD 회원국 기준 정부 총지출 중 조달지출 비중 약 34%",
            "공공조달과 민간구매의 근본적 차이: 경제·환경·사회적 가치 고려 의무",
            "공공조달의 순환적 수명주기(Life Cycle) 5단계 이해"
          ],
          related_topic_slugs: ["public-procurement-overview"]
        },
        {
          number: 2,
          title: "공공조달 원칙 및 방법",
          sections: [
            "공공조달 원칙",
            "경쟁적 공공조달 방법",
            "비경쟁적 공공조달 방법"
          ],
          learning_objectives: [
            "공공조달의 핵심 원칙(VFM·윤리·경쟁·투명성·책임성) 설명",
            "경쟁적 공공조달 방법의 종류와 특징 설명",
            "비경쟁적 공공조달(수의계약) 방법의 요건과 한계 설명"
          ],
          keywords: [
            "VFM(Value For Money)",
            "윤리(Ethics)",
            "경쟁(Competition)",
            "투명성(Transparency)",
            "책임성(Accountability)",
            "공개경쟁입찰",
            "제한경쟁입찰",
            "수의계약"
          ],
          exam_points: [
            "공공조달 5대 원칙: VFM·윤리·경쟁·투명성·책임성 암기",
            "경쟁적 방법: 공개경쟁·제한경쟁·지명경쟁 구분",
            "비경쟁적 방법: 수의계약의 허용 요건 및 금액 기준"
          ],
          related_topic_slugs: ["private-contract", "bidding", "bid-qualification"]
        },
        {
          number: 3,
          title: "전자조달시스템의 이해",
          sections: [
            "전자조달시스템 개요",
            "국가종합전자조달시스템(나라장터)",
            "국가종합전자조달시스템(나라장터) 연계 계약 관리 지원시스템 개요",
            "목록정보시스템 개요"
          ],
          learning_objectives: [
            "전자조달시스템의 개요와 주요 기능 이해",
            "나라장터의 주요 기능과 서비스 설명",
            "나라장터 연계 계약 관리 지원시스템 개요 이해",
            "목록정보시스템의 개요와 활용 방법 이해"
          ],
          keywords: [
            "전자조달시스템(e-Procurement System)",
            "나라장터(KONEPS)",
            "목록정보시스템",
            "전자입찰",
            "인증서",
            "조달청"
          ],
          exam_points: [
            "나라장터(KONEPS): 국가종합전자조달시스템 — 조달청 운영",
            "입찰참가자격 등록: 나라장터 통해 필수 등록",
            "목록정보시스템: 품목 코드·규격 관리 체계"
          ],
          related_topic_slugs: ["e-procurement-guide", "e-bidding"]
        },
        {
          number: 4,
          title: "전략적 공공조달",
          sections: [
            "전략적 공공조달",
            "중소기업 조달",
            "녹색공공조달",
            "혁신을 위한 공공조달",
            "사회적 책임조달"
          ],
          learning_objectives: [
            "전략적 공공조달의 개념과 목적 이해",
            "중소기업 조달 지원 제도 설명",
            "녹색공공조달(GPP) 개념 및 정책 이해",
            "혁신조달(IPP) 개념 이해",
            "사회적 책임조달(SRPP) 개념 이해"
          ],
          keywords: [
            "전략적 공공조달",
            "중소기업 조달",
            "녹색공공조달(GPP: Green Public Procurement)",
            "혁신조달(IPP: Innovative Public Procurement)",
            "사회적 책임조달(SRPP: Socially Responsible Public Procurement)"
          ],
          exam_points: [
            "GPP(Green Public Procurement): 환경부담 최소화 조달",
            "IPP(Innovative Public Procurement): 기술혁신 촉진 조달",
            "SRPP(Socially Responsible Public Procurement): 사회적 가치 조달",
            "3대 전략조달 약어 및 개념 암기"
          ],
          related_topic_slugs: ["mas-contract"]
        },
        {
          number: 5,
          title: "전략적 조달의 활용",
          sections: [
            "공공조달 우선구매 제도 개요",
            "중소기업지원 조달",
            "녹색조달",
            "혁신·기술개발 촉진조달",
            "사회적 책임조달"
          ],
          learning_objectives: [
            "공공조달 우선구매 제도의 종류와 요건 설명",
            "중소기업 지원 조달 제도의 실무 적용 방법 설명",
            "녹색조달 실무 절차 이해",
            "혁신·기술개발 촉진조달 제도 이해",
            "사회적 책임조달 실무 적용 이해"
          ],
          keywords: [
            "우선구매",
            "중소기업 적합업종",
            "녹색제품",
            "혁신제품",
            "사회적기업",
            "장애인기업"
          ],
          exam_points: [
            "중소기업 제품 구매 목표 비율 준수 의무",
            "녹조제품·환경표지 인증제품 우선구매 요건",
            "사회적기업·장애인기업 생산품 우선구매 법적 근거"
          ],
          related_topic_slugs: [
            "goods-selection-committee",
            "spec-price-split-bid",
            "goods-vs-service-contract"
          ]
        },
        {
          number: 6,
          title: "공공조달 법률 이해",
          sections: [
            "공공계약(국가 및 지방) 법령의 이해",
            "공공계약 관련 민법 규정의 이해",
            "조달사업법령의 이해",
            "전자조달법령의 이해",
            "공기업·준정부기관 계약사무규칙",
            "국가계약법과 지방계약법의 주요 차이점"
          ],
          learning_objectives: [
            "국가계약법·지방계약법의 체계와 주요 내용 이해",
            "공공계약 관련 민법 규정의 적용 방법 이해",
            "조달사업법의 목적과 주요 내용 이해",
            "전자조달법의 목적과 주요 내용 이해",
            "국가계약법과 지방계약법의 주요 차이점 설명"
          ],
          keywords: [
            "국가계약법",
            "지방계약법",
            "조달사업법",
            "전자조달법",
            "계약사무규칙",
            "신의성실의 원칙",
            "부당특약 금지"
          ],
          exam_points: [
            "국가계약법 vs 지방계약법: 적용 대상·주요 차이점 비교 출제 빈출",
            "국가계약법 제5조(계약의 원칙): 신의성실, 부당특약 금지",
            "조달사업법: 조달청 중앙조달 근거법",
            "전자조달법: 나라장터 법적 근거"
          ],
          related_topic_slugs: ["national-vs-local-contract-law"]
        },
        {
          number: 7,
          title: "공공조달 분쟁관리",
          sections: [
            "공공조달 법규 분쟁 및 해석",
            "공공조달 및 계약 관련 법규 위반시 제재"
          ],
          learning_objectives: [
            "공공조달 관련 법규 분쟁의 유형과 해석 방법 이해",
            "공공조달 및 계약 법규 위반 시 제재 종류 설명"
          ],
          keywords: [
            "입찰참가자격 제한",
            "부정당업자",
            "입찰무효",
            "계약해제·해지",
            "손해배상",
            "행정심판",
            "이의신청"
          ],
          exam_points: [
            "부정당업자 제재: 입찰참가자격 제한 기간 기준",
            "입찰무효 사유: 무자격·부정당·허위서류 제출 등",
            "이의신청 기간: 처분 통보 후 15일 이내"
          ],
          related_topic_slugs: ["bid-participation-restriction"]
        }
      ]
    },

    # ────────────────────────────────────────────────────────────
    # 2권: 공공조달 계획분석 — 입찰 및 낙찰 절차 일반
    # ────────────────────────────────────────────────────────────
    {
      id: 2,
      number: "2권",
      title: "공공조달 계획분석",
      subtitle: "입찰 및 낙찰 절차 일반",
      color: "blue",
      icon: "analytics",
      total_chapters: 6,
      chapters: [
        {
          number: 1,
          title: "공공조달 계획수립",
          sections: [
            "공공 조달계획수립 개요",
            "시장조사",
            "입찰 및 낙찰",
            "계약관리",
            "계약완료 및 종결"
          ],
          learning_objectives: [
            "조달계획 단계의 세부과업을 이해하고 설명",
            "시장조사 단계의 세부과업을 이해하고 설명",
            "입찰 및 낙찰 단계의 세부과업을 이해하고 설명",
            "계약관리 단계의 세부과업을 이해하고 설명",
            "계약종결 단계의 세부과업을 이해하고 설명"
          ],
          keywords: [
            "공공조달계획(Public Procurement Plan)",
            "요구식별(Identification Needs)",
            "시장조사(Market Research)",
            "구매사양(Purchase Specification)",
            "과업명세서(SOW: Statement of Work)",
            "입찰 및 낙찰(Solicitation and Award)",
            "계약관리(Contract Management)",
            "계약완료 및 종결(Contract Completion and Closeout)"
          ],
          exam_points: [
            "조달 수명주기 5단계: 조달계획→시장조사→입찰낙찰→계약관리→계약완료",
            "SOW(Statement of Work): 과업명세서 — 과업 범위 상세 설명 문서",
            "조달계획 단계 3대 과업: 요구사항 식별, 조달사업팀 구성, 조달전략계획 개발"
          ],
          related_topic_slugs: ["estimated-price", "bid-qualification"]
        },
        {
          number: 2,
          title: "공공조달 입찰 실행절차",
          sections: [
            "입찰공고(Solicitation)",
            "평가(Evaluation)",
            "낙찰자선정 검토(Review) 및 승인(Approval)",
            "계약체결(Contract)"
          ],
          learning_objectives: [
            "입찰공고의 요건과 종류 설명",
            "입찰 평가 기준과 방법 이해",
            "낙찰자 선정 검토 및 승인 절차 이해",
            "계약체결 절차와 요건 이해"
          ],
          keywords: [
            "입찰공고(Solicitation)",
            "평가(Evaluation)",
            "낙찰자 선정(Award)",
            "계약체결(Contract)",
            "사전규격공개",
            "입찰공고 기간"
          ],
          exam_points: [
            "입찰공고 기간: 일반 40일 이상(5억 이상 공사 60일), 긴급 10일",
            "사전규격공개: 입찰 전 규격 공개 의무 (5천만원 이상)",
            "낙찰자 결정 방법: 최저가·종합평가·협상에 의한 계약 구분"
          ],
          related_topic_slugs: ["bidding", "e-bidding", "dual-quote", "qualification-failure"]
        },
        {
          number: 3,
          title: "공급업체의 공급계획 수립",
          sections: [
            "공공조달 수요분석 및 공급계획",
            "입찰공고 법적 적정성(공급환경) 분석",
            "입찰공고 기술적 적정성(내부 공급 역량) 분석",
            "입찰공고 경제적 적정성 분석",
            "공공조달 포트폴리오 분석"
          ],
          learning_objectives: [
            "공급업체 관점에서의 수요분석 및 공급계획 수립 방법 이해",
            "입찰공고의 법적·기술적·경제적 적정성 분석 방법 이해",
            "공공조달 포트폴리오 분석 방법 이해"
          ],
          keywords: [
            "공급계획",
            "수요분석",
            "법적 적정성",
            "기술적 적정성",
            "경제적 적정성",
            "포트폴리오 분석"
          ],
          exam_points: [
            "입찰 참여 적정성 분석 3요소: 법적·기술적·경제적 적정성",
            "공급업체 포트폴리오 분석: 조달 시장에서의 전략적 위치 파악"
          ],
          related_topic_slugs: ["mas-contract", "price-negotiation"]
        },
        {
          number: 4,
          title: "조달요구 응답 및 제안",
          sections: [
            "조달요구 응답 절차",
            "사전규격공개 분석",
            "입찰공고문 분석",
            "입찰 및 제안요청 설명회",
            "투찰과 개찰"
          ],
          learning_objectives: [
            "조달요구 응답 절차 이해",
            "사전규격공개 분석 방법 이해",
            "입찰공고문 분석 방법 이해",
            "입찰 및 제안요청 설명회 참여 방법 이해",
            "투찰과 개찰 절차 이해"
          ],
          keywords: [
            "사전규격공개",
            "입찰공고문",
            "제안요청서(RFP)",
            "투찰",
            "개찰",
            "입찰설명회"
          ],
          exam_points: [
            "사전규격공개: 추정가격 5천만원 이상 물품·용역 적용",
            "투찰: 전자입찰 시스템을 통한 투찰가격 제출",
            "개찰: 투찰 마감 후 전자 개봉 — 최저가 순 확인"
          ],
          related_topic_slugs: ["e-bidding", "price-negotiation"]
        },
        {
          number: 5,
          title: "입찰·제안평가 및 계약체결",
          sections: [
            "입찰·제안평가 절차",
            "평가위원회 구성 및 이해 충돌 방지",
            "계약의 협상",
            "낙찰자 결정 방법",
            "입찰 결과 분석 및 이의제기",
            "계약 체결"
          ],
          learning_objectives: [
            "입찰·제안평가 절차 이해",
            "평가위원회 구성 요건 및 이해충돌 방지 조치 이해",
            "계약 협상 방법 이해",
            "낙찰자 결정 방법별 특징 설명",
            "입찰 결과 분석 및 이의제기 방법 이해",
            "계약 체결 요건과 절차 이해"
          ],
          keywords: [
            "평가위원회",
            "이해충돌",
            "협상에 의한 계약",
            "종합심사낙찰제",
            "최저가낙찰제",
            "낙찰하한율",
            "이의신청"
          ],
          exam_points: [
            "낙찰 결정 3대 방식: 최저가·종합심사(적격심사)·협상 계약",
            "낙찰하한율: 2억원 이상 공사 89.745% (2026 기준)",
            "평가위원회: 2/3 이상 외부 위원 구성 원칙",
            "이의신청: 낙찰자 결정 통보 후 7일 이내"
          ],
          related_topic_slugs: ["qualification-failure", "price-negotiation", "contract-guarantee-deposit", "lowest-bid-rate"]
        },
        {
          number: 6,
          title: "공공조달 리스크 관리",
          sections: [
            "리스크 관리 개요",
            "공공조달 리스크 관리",
            "공공조달 단계별 리스크 관리 방안"
          ],
          learning_objectives: [
            "리스크 관리의 개념과 중요성 이해",
            "공공조달에서의 주요 리스크 유형 설명",
            "공공조달 단계별 리스크 관리 방안 설명"
          ],
          keywords: [
            "리스크 관리",
            "리스크 식별",
            "리스크 평가",
            "리스크 대응",
            "조달 단계별 리스크"
          ],
          exam_points: [
            "리스크 관리 4단계: 식별→평가→대응→모니터링",
            "조달 단계별 주요 리스크: 계획(수요오류)→입찰(담합)→계약(이행불이행)"
          ],
          related_topic_slugs: [
            "contract-termination",
            "defect-warranty",
            "performance-guarantee",
            "late-penalty"
          ]
        }
      ]
    },

    # ────────────────────────────────────────────────────────────
    # 3권: 공공계약관리 — 물품/용역/공사계약 일반
    # ────────────────────────────────────────────────────────────
    {
      id: 3,
      number: "3권",
      title: "공공계약관리",
      subtitle: "물품/용역/공사계약 일반",
      color: "violet",
      icon: "contract",
      total_chapters: 6,
      chapters: [
        {
          number: 1,
          title: "계약관리 일반 절차",
          sections: [
            "효과적 계약관리 계획",
            "계약변경 관리",
            "안정적 계약 이행 관리",
            "계약 종결 관리"
          ],
          learning_objectives: [
            "계약의 원칙과 요건 이해",
            "계약의 변경 요건과 절차를 이해",
            "계약 성과관리 방법론 이해",
            "납품검사 및 대금의 지급 등 계약의 종결절차 이해"
          ],
          keywords: [
            "계약관리(Contract Management)",
            "계약관리 절차(Contract Management Process)",
            "계약변경(Contract Change)",
            "계약종결 절차(Contract Termination Process)",
            "신의성실의 원칙",
            "계약자유의 원칙"
          ],
          exam_points: [
            "공공계약의 법적 성격: '사적자치가 적용되는 사법(私法)계약'(대법원)",
            "계약 4대 자유: 체결·상대방 선택·내용 결정·방식의 자유",
            "국가계약법 제5조(계약 원칙): 신의성실, 상호 대등한 입장",
            "계약변경 요건: 물가변동·설계변경·기타 계약내용 변경"
          ],
          related_topic_slugs: ["contract-guarantee-deposit", "late-penalty", "payment", "design-change", "contract-termination"]
        },
        {
          number: 2,
          title: "물품 계약관리",
          sections: [
            "물품계약 일반절차 관리",
            "물품구매·제조 낙찰자 결정 방법",
            "물품계약 이행관리"
          ],
          learning_objectives: [
            "물품계약의 일반절차 이해",
            "물품구매·제조 낙찰자 결정 방법 이해",
            "물품계약 이행관리 방법 이해"
          ],
          keywords: [
            "물품계약",
            "물품구매",
            "물품제조",
            "적격심사",
            "물품구매심의위원회",
            "납품",
            "검사"
          ],
          exam_points: [
            "물품 적격심사: 2억원 미만 소액 물품 — 납품실적·가격 심사",
            "물품구매심의위원회: 고액 물품 구매 시 심의 절차",
            "납품검사: 계약 수량·규격 확인 후 대금지급"
          ],
          related_topic_slugs: ["goods-vs-service-contract", "goods-selection-committee", "inspection", "late-penalty"]
        },
        {
          number: 3,
          title: "용역·다수공급자 계약 관리",
          sections: [
            "용역계약 절차 및 이행관리",
            "다수공급자계약(MAS) 절차 및 이행관리"
          ],
          learning_objectives: [
            "용역계약의 특성과 절차 이해",
            "용역계약 이행관리 방법 이해",
            "다수공급자계약(MAS) 절차 및 이행관리 이해"
          ],
          keywords: [
            "용역계약",
            "다수공급자계약(MAS: Multiple Award Schedule)",
            "단가계약",
            "용역 대가기준",
            "기성검사"
          ],
          exam_points: [
            "MAS(다수공급자계약): 2인 이상 공급자와 계약 — 수요기관 직접 2차 계약",
            "용역계약 대금: 착수금·중도금·잔금 분할 지급 가능",
            "기성검사: 용역·공사 진행 단계별 이행 확인"
          ],
          related_topic_slugs: ["mas-contract", "unit-price-contract", "payment"]
        },
        {
          number: 4,
          title: "공사계약관리",
          sections: [
            "공사계약 일반 개요",
            "건설엔지니어링",
            "공사계약",
            "기술형공사 수행 방식",
            "공사단계"
          ],
          learning_objectives: [
            "공사계약의 특성과 일반적인 절차 이해",
            "건설엔지니어링의 개념과 역할 이해",
            "공사계약 체결 방법과 요건 이해",
            "기술형공사(턴키·대안) 수행 방식 이해",
            "공사 단계별(착공→시공→준공) 관리 방법 이해"
          ],
          keywords: [
            "공사계약",
            "건설엔지니어링",
            "턴키(Turn-Key)",
            "대안입찰",
            "기성금",
            "준공",
            "하자보증"
          ],
          exam_points: [
            "턴키(일괄입찰): 설계+시공 일괄 수행 방식",
            "대안입찰: 발주기관 원안에 대한 대안 제시 방식",
            "기성검사: 공사 진행 단계별 이행 확인 후 기성금 지급",
            "하자담보책임: 준공 후 1~10년(시설물 종류에 따라)"
          ],
          related_topic_slugs: ["design-change", "subcontract", "price-escalation", "defect-warranty"]
        },
        {
          number: 5,
          title: "공공조달 품질관리",
          sections: [
            "공공조달 품질관리",
            "해외 공공조달 품질관리",
            "직접생산확인 및 품질점검",
            "안전관리물자 지정제도",
            "품질보증조달물품 지정제도"
          ],
          learning_objectives: [
            "공공조달 품질관리의 개념과 방법 이해",
            "해외 공공조달 품질관리 기준 이해",
            "직접생산확인 및 품질점검 절차 이해",
            "안전관리물자 지정제도 이해",
            "품질보증조달물품 지정제도 이해"
          ],
          keywords: [
            "품질관리",
            "직접생산확인",
            "품질점검",
            "안전관리물자",
            "품질보증조달물품",
            "KS인증"
          ],
          exam_points: [
            "직접생산확인: 제조업체가 직접 생산하는지 확인하는 제도",
            "품질보증조달물품: 조달청이 품질 보증하는 물품 지정",
            "안전관리물자: 안전 관련 핵심 물자 품질 강화 관리"
          ],
          related_topic_slugs: ["inspection"]
        },
        {
          number: 6,
          title: "공공조달 기술품질 제품",
          sections: [
            "벤처나라(벤처창업혁신조달상품) 등록제도",
            "혁신시제품 시범구매제도",
            "우수조달물품(우수제품) 지정제도"
          ],
          learning_objectives: [
            "벤처나라 등록 요건과 절차 이해",
            "혁신시제품 시범구매제도 이해",
            "우수조달물품(우수제품) 지정 요건과 절차 이해"
          ],
          keywords: [
            "벤처나라",
            "혁신시제품",
            "시범구매",
            "우수조달물품",
            "우수제품",
            "혁신제품 조달"
          ],
          exam_points: [
            "벤처나라: 벤처·창업기업 혁신 제품 조달 전용 플랫폼",
            "혁신시제품: 시장 미검증 혁신 제품 공공기관 시범 구매 제도",
            "우수조달물품: 품질·성능 우수 인정 — 종합쇼핑몰 등재 우선 혜택"
          ],
          related_topic_slugs: ["mas-contract"]
        }
      ]
    },

    # ────────────────────────────────────────────────────────────
    # 4권: 공공조달 관리실무 — 전자조달기반 수행절차 일반
    # ────────────────────────────────────────────────────────────
    {
      id: 4,
      number: "4권",
      title: "공공조달 관리실무",
      subtitle: "전자조달기반 수행절차 일반",
      color: "rose",
      icon: "settings",
      total_chapters: 9,
      chapters: [
        {
          number: 1,
          title: "공공조달 계획 수립",
          sections: [
            "나라장터 사용자 등록",
            "공급대상물 유형별(물품, 용역, 공사) 품명 등록(물품목록화)"
          ],
          learning_objectives: [
            "나라장터 등록절차를 이해하고 실행",
            "입찰참가자격등록을 위한 품명을 등록 절차를 이해하고 실행",
            "직접생산확인기준을 이해하고 작성",
            "목록화 절차를 이해하고 실행"
          ],
          keywords: [
            "나라장터 사용자 등록",
            "입찰참가자격 등록",
            "품명 등록",
            "물품목록화",
            "직접생산확인기준",
            "조달청"
          ],
          exam_points: [
            "나라장터 등록 5단계: 개인회원가입→이용약관동의→등록신청→서류제출→승인",
            "물품목록화: 물품 코드 부여 — 조달 참가의 선결 조건",
            "직접생산확인기준 작성: 납품 가능 규격·수량·생산설비 기준 명시"
          ],
          related_topic_slugs: ["e-procurement-guide"]
        },
        {
          number: 2,
          title: "공급계획 수립",
          sections: [
            "공급정보 수집과 분석",
            "조달데이터 분석 및 예측",
            "공급대상 수요기관 선정"
          ],
          learning_objectives: [
            "공급정보 수집과 분석 방법 이해",
            "조달데이터 분석 및 예측 방법 이해",
            "공급대상 수요기관 선정 방법 이해"
          ],
          keywords: [
            "공급정보",
            "조달데이터",
            "수요기관",
            "나라장터 공고 분석",
            "예측 모델"
          ],
          exam_points: [
            "나라장터 공고 분석: 과거 조달 실적 데이터 활용 수요 예측",
            "수요기관 선정: 품목별·지역별 수요기관 우선순위 결정"
          ],
          related_topic_slugs: [
            "bid-announcement",
            "e-procurement-guide",
            "long-term-contract",
            "unit-price-contract"
          ]
        },
        {
          number: 3,
          title: "발주대상의 경제성 분석(원가계산)",
          sections: [
            "공공조달 원가계산",
            "제조원가계산",
            "용역원가계산",
            "공사원가계산"
          ],
          learning_objectives: [
            "공공조달 원가계산의 개념과 목적 이해",
            "제조원가계산 방법 이해",
            "용역원가계산 방법 이해",
            "공사원가계산 방법 이해"
          ],
          keywords: [
            "원가계산",
            "제조원가",
            "용역원가",
            "공사원가",
            "직접비",
            "간접비",
            "일반관리비",
            "이윤"
          ],
          exam_points: [
            "원가 구성: 직접비 + 간접비 + 일반관리비 + 이윤",
            "일반관리비율·이윤율: 원가계산 요령 고시 기준값 적용",
            "용역원가 인건비: 노임단가 × 투입공수(M/M) 기준 산출",
            "공사원가: 재료비+노무비+경비+일반관리비+이윤+부가세"
          ],
          related_topic_slugs: ["cost-calculation-guide", "estimated-price"]
        },
        {
          number: 4,
          title: "입찰 및 낙찰절차 관리",
          sections: [
            "제안서 작성",
            "제안평가",
            "기술(규격)협상과 가격협상"
          ],
          learning_objectives: [
            "제안서 작성 방법과 요건 이해",
            "제안평가 기준과 절차 이해",
            "기술협상과 가격협상 방법 이해"
          ],
          keywords: [
            "제안서(Proposal)",
            "기술제안서",
            "가격제안서",
            "기술협상",
            "가격협상",
            "최종 낙찰자"
          ],
          exam_points: [
            "협상에 의한 계약: 기술협상 후 가격협상 순서 준수",
            "제안서 평가: 기술능력·가격·납기·관리능력 등 종합 평가",
            "가격협상: 예정가격 이내에서 낙찰가 결정"
          ],
          related_topic_slugs: ["price-negotiation", "qualification-failure"]
        },
        {
          number: 5,
          title: "공공조달 계약 체결 관리",
          sections: [
            "계약체결",
            "착수보고와 착공(착수)계 제출",
            "계약이행 보증 관리"
          ],
          learning_objectives: [
            "계약체결 절차와 요건 이해",
            "착수보고 및 착공계 제출 요건 이해",
            "계약이행 보증 관리 방법 이해"
          ],
          keywords: [
            "계약체결",
            "착수보고",
            "착공계",
            "계약이행보증",
            "이행보증금",
            "계약보증금"
          ],
          exam_points: [
            "계약보증금: 계약금액의 10~15% 납부 원칙",
            "착공계: 공사 착수 전 제출 — 착수 일자, 현장 대리인 명기",
            "이행보증서: 계약이행 보증보험증권 또는 현금 납부"
          ],
          related_topic_slugs: ["contract-guarantee-deposit", "payment"]
        },
        {
          number: 6,
          title: "공급 대상물 유형별 계약 관리",
          sections: [
            "공통 조달관리 절차 수행",
            "물품계약 입찰 절차 수행",
            "용역계약 입찰 절차 수행",
            "공사계약 특화 절차 수행"
          ],
          learning_objectives: [
            "공통 조달관리 절차 이해",
            "물품계약 입찰 절차 실행 방법 이해",
            "용역계약 입찰 절차 실행 방법 이해",
            "공사계약 특화 절차 이해"
          ],
          keywords: [
            "물품 입찰",
            "용역 입찰",
            "공사 입찰",
            "검수",
            "기성",
            "준공"
          ],
          exam_points: [
            "물품·용역·공사 낙찰자 결정 방식 차이 출제 빈출",
            "검수(물품)·기성검사(용역/공사): 이행 확인 후 대금지급",
            "공사 특화: 착공→기성→준공 3단계 관리"
          ],
          related_topic_slugs: ["goods-vs-service-contract", "inspection", "late-penalty", "payment"]
        },
        {
          number: 7,
          title: "종합쇼핑몰 활용",
          sections: [
            "다수공급자계약(MAS) 절차",
            "우수제품 신청 절차"
          ],
          learning_objectives: [
            "다수공급자계약(MAS) 절차 실행 방법 이해",
            "우수제품 신청 절차와 요건 이해"
          ],
          keywords: [
            "종합쇼핑몰",
            "나라장터 쇼핑몰",
            "MAS(다수공급자계약)",
            "2차 계약",
            "우수제품 신청",
            "견적요청"
          ],
          exam_points: [
            "MAS 2차 계약: 수요기관이 종합쇼핑몰에서 직접 견적요청→계약",
            "우수제품 등록: 품질·성능 우수 → 종합쇼핑몰 우선 등재",
            "MAS 견적요청 기준: 2천만원 초과 시 3개사 이상 견적"
          ],
          related_topic_slugs: ["mas-contract"]
        },
        {
          number: 8,
          title: "공공조달 법제도 활용",
          sections: [
            "공공조달법규 활용",
            "전략적 공공조달 우선구매제도 활용"
          ],
          learning_objectives: [
            "공공조달 관련 법규 활용 방법 이해",
            "전략적 공공조달 우선구매제도 활용 방법 이해"
          ],
          keywords: [
            "공공조달법규",
            "우선구매제도",
            "중소기업 우선구매",
            "녹색제품 우선구매",
            "사회적기업 우선구매"
          ],
          exam_points: [
            "공공기관 중소기업 제품 구매 목표: 중소기업청 고시 비율 이상",
            "녹색제품 구매촉진법: 공공기관 녹색제품 의무구매",
            "사회적기업 육성법: 사회적기업 생산품 우선구매 의무"
          ],
          related_topic_slugs: ["national-vs-local-contract-law"]
        },
        {
          number: 9,
          title: "공공예산관리 실무",
          sections: [
            "예산과목 체계 및 편성 기준",
            "예산 집행 절차 및 지출원인행위",
            "예산 이용·전용·이월",
            "추가경정예산 편성",
            "예비비 편성 및 사용",
            "결산 절차",
            "국고보조금 관리",
            "지방채 발행 및 재정건전성",
            "지방자치단체 복식부기 회계"
          ],
          learning_objectives: [
            "예산과목(장·관·항·세항·세세항·목) 체계 이해",
            "예산 집행 절차와 지출원인행위의 개념 이해",
            "예산 이용·전용·전용의 허용 요건과 절차 이해",
            "추가경정예산 편성 요건과 절차 이해",
            "예비비 한도 및 사용 절차 이해",
            "결산 절차와 의회 승인 과정 이해",
            "국고보조금 집행·정산·반납 절차 이해",
            "지방채 발행 요건과 채무비율 기준 이해",
            "복식부기 회계(재정상태표·재정운영표) 개념 이해"
          ],
          keywords: [
            "예산과목",
            "지출원인행위",
            "이용·전용",
            "이월(명시이월·사고이월)",
            "추가경정예산",
            "예비비(일반예비비·목적예비비)",
            "결산",
            "국고보조금",
            "지방채",
            "채무비율",
            "복식부기",
            "발생주의"
          ],
          exam_points: [
            "지출원인행위: 계약 체결 시 예산을 지정·확보하는 행위 — 집행의 시작",
            "이용: 예산의 장(章) 간 상호 융통 — 의회 의결 필요",
            "전용: 세항·목 간 융통 — 행정안전부장관 또는 단체장 승인",
            "명시이월: 연도 내 지출 못할 것이 명백한 경우 예산으로 미리 의결",
            "사고이월: 불가피한 사유로 연도 내 미집행 → 다음 연도로 이월",
            "예비비 한도: 일반회계 예산 총액의 1% 이내 (지방재정법 제43조)",
            "결산 의회 제출: 회계연도 종료 후 90일 이내",
            "국고보조금: 용도 외 사용 시 반납 의무, 지도·감독 수인 의무",
            "지방채 행안부 승인: 채무비율 25% 초과 시 필요",
            "복식부기 4대 재무제표: 재정상태표·재정운영표·현금흐름표·순자산변동표"
          ],
          related_topic_slugs: [
            "budget-item-standard",
            "expenditure-commitment",
            "budget-execution",
            "budget-transfer",
            "budget-lapse",
            "supplementary-budget",
            "contingency-fund",
            "budget-settlement",
            "national-subsidy",
            "public-debt-management",
            "local-government-accounting",
            "accounting-officers"
          ]
        }
      ]
    }
  ].freeze

  # 챕터 키→제목 맵 { "1-1" => { title: ..., subject_number: ... } }
  def self.chapter_map
    result = {}
    SUBJECTS.each do |s|
      s[:chapters].each do |c|
        result["#{s[:id]}-#{c[:number]}"] = { title: c[:title], subject_number: s[:number] }
      end
    end
    result
  end

  # 과목 찾기
  def self.find_subject(id)
    SUBJECTS.find { |s| s[:id] == id.to_i }
  end

  # 챕터 찾기
  def self.find_chapter(subject_id, chapter_number)
    subject = find_subject(subject_id)
    return nil unless subject
    subject[:chapters].find { |c| c[:number] == chapter_number.to_i }
  end

  # 전체 키워드 목록 (과목·챕터 정보 포함)
  def self.all_keywords
    result = []
    SUBJECTS.each do |subject|
      subject[:chapters].each do |chapter|
        chapter[:keywords].each do |keyword|
          result << {
            keyword: keyword,
            subject_id: subject[:id],
            subject_title: subject[:title],
            subject_number: subject[:number],
            subject_color: subject[:color],
            chapter_number: chapter[:number],
            chapter_title: chapter[:title]
          }
        end
      end
    end
    result
  end

  # 과목별 색상 Tailwind 클래스
  SUBJECT_COLORS = {
    "emerald" => {
      bg: "bg-emerald-50",
      bg_dark: "bg-emerald-600",
      border: "border-emerald-200",
      text: "text-emerald-700",
      text_dark: "text-emerald-600",
      badge: "bg-emerald-100 text-emerald-800",
      hover_border: "hover:border-emerald-400",
      icon_bg: "bg-emerald-100",
      progress: "bg-emerald-500"
    },
    "blue" => {
      bg: "bg-blue-50",
      bg_dark: "bg-blue-600",
      border: "border-blue-200",
      text: "text-blue-700",
      text_dark: "text-blue-600",
      badge: "bg-blue-100 text-blue-800",
      hover_border: "hover:border-blue-400",
      icon_bg: "bg-blue-100",
      progress: "bg-blue-500"
    },
    "violet" => {
      bg: "bg-violet-50",
      bg_dark: "bg-violet-600",
      border: "border-violet-200",
      text: "text-violet-700",
      text_dark: "text-violet-600",
      badge: "bg-violet-100 text-violet-800",
      hover_border: "hover:border-violet-400",
      icon_bg: "bg-violet-100",
      progress: "bg-violet-500"
    },
    "rose" => {
      bg: "bg-rose-50",
      bg_dark: "bg-rose-600",
      border: "border-rose-200",
      text: "text-rose-700",
      text_dark: "text-rose-600",
      badge: "bg-rose-100 text-rose-800",
      hover_border: "hover:border-rose-400",
      icon_bg: "bg-rose-100",
      progress: "bg-rose-500"
    }
  }.freeze

  def self.colors(color_name)
    SUBJECT_COLORS[color_name] || SUBJECT_COLORS["blue"]
  end
end
