module ToolsHelper
  # 실무 도구 레지스트리 — tools/index 뷰 + silmu-search 도구 검색 공용 소스.
  # path는 route helper를 그대로 사용(헬퍼 컨텍스트에서 동작).
  # keywords는 선택 필드 — 제로결과 검색어 기반 발견성 보강용.
  def tools_registry
    [
      { title: "계약방식 결정 도우미",         desc: "추정가격과 계약유형으로 적정 계약방식과 필요서류를 확인합니다.",                icon: "gavel",            color: "emerald", category: "자동화 도구", domain: "계약", path: contract_method_path,               badge: "인기", keywords: "수의계약, 입찰, 추정가격" },
      { title: "계약서류 원클릭 생성기",        desc: "물품/용역/공사별 필수 계약서류 체크리스트를 자동 생성합니다.",                  icon: "fact_check",        color: "blue",    category: "문서 도구",   domain: "계약", path: contract_documents_path },
      { title: "소요예산 추정기",               desc: "소규모 공사/용역 시행 전 대략적인 예산을 미리 추정합니다.",                     icon: "calculate",         color: "indigo",  category: "계산기",      domain: "예산", path: budget_estimator_path },
      { title: "견적서 검토 도구",              desc: "견적서의 적정성을 자동으로 검토합니다.",                                        icon: "fact_check",        color: "indigo",  category: "문서 도구",   domain: "계약", path: "/tools/quote-review",              badge: "인기" },
      { title: "계약문서 생성기",               desc: "시방서·구매규격서·과업내용서(과업지시서)를 단계별로 작성합니다.",               icon: "description",       color: "emerald", category: "문서 도구",   domain: "계약", path: "/forms/과업지시서.html" },
      { title: "PDF 도구",                     desc: "PDF 분할, 합치기, 쪽번호 매기기를 간편하게 처리합니다.",                        icon: "picture_as_pdf",    color: "amber",   category: "문서 도구",   domain: "기타", path: pdf_tools_path },
      { title: "여비계산기",                   desc: "출장 여비(운임, 숙박비, 식비, 일비)를 자동으로 계산합니다.",                    icon: "directions_car",    color: "indigo",  category: "계산기",      domain: "여비", path: travel_calculator_path,             badge: "인기", keywords: "출장비, 일비, 식비, 숙박비, 운임, 자가용" },
      { title: "물량내역서+시방서 생성기",      desc: "소액공사 간이 물량내역서와 시방서를 간편하게 작성합니다.",                      icon: "receipt_long",      color: "blue",    category: "문서 도구",   domain: "계약", path: cost_estimate_path },
      { title: "설계변경 검토서 도우미",        desc: "설계변경 사유별 검토서와 절차 체크리스트를 자동 생성합니다.",                    icon: "swap_horiz",        color: "emerald", category: "문서 도구",   domain: "계약", path: design_change_path },
      { title: "기성검사 체크리스트",           desc: "공사 유형별 기성검사 항목을 자동으로 생성합니다.",                              icon: "checklist",         color: "amber",   category: "체크리스트",  domain: "계약", path: progress_inspection_path },
      { title: "원가계산서 검토 가이드",        desc: "용역 원가계산서 항목별 적정성을 자동으로 검토합니다.",                          icon: "price_check",       color: "indigo",  category: "자동화 도구", domain: "계약", path: cost_calculation_path },
      { title: "추정가격 계산기",               desc: "계약유형별 원가항목을 입력하여 추정가격과 복수예비가격을 산출합니다.",            icon: "calculate",         color: "emerald", category: "계산기",      domain: "계약", path: estimated_price_path },
      { title: "법정기간 계산기",               desc: "입찰공고·계약체결·대금지급·하자보증·지체상금 기한을 자동 계산합니다.",           icon: "calendar_month",    color: "amber",   category: "계산기",      domain: "계약", path: legal_period_path,                  badge: "인기" },
      { title: "계약보증금 계산기",             desc: "계약보증금·하자보증금·인지세를 계약금액에 따라 자동으로 계산합니다.",            icon: "shield",            color: "indigo",  category: "계산기",      domain: "계약", path: contract_guarantee_path },
      { title: "적격심사 자동 채점기",          desc: "2억원 이상 공사·용역 입찰의 적격심사 점수를 자동으로 계산합니다.",               icon: "fact_check",        color: "emerald", category: "계산기",      domain: "계약", path: qualification_evaluation_path,      badge: "NEW" },
      { title: "업무 할일 달력",               desc: "급여·세무·보험·회계 등 월별 반복 업무를 한눈에 확인하고 체크합니다.",           icon: "calendar_month",    color: "blue",    category: "체크리스트",  domain: "기타", path: task_calendar_path,                 badge: "NEW" },
      { title: "사업계획서 생성기",             desc: "사업정보를 입력하면 공문 서식의 사업계획서를 자동 생성합니다.",                  icon: "assignment",        color: "indigo",  category: "문서 도구",   domain: "계약", path: project_plan_path },
      { title: "수의계약 사유서 생성기",        desc: "계약구분과 사유를 선택하면 법적 근거가 포함된 사유서를 자동 생성합니다.",         icon: "edit_document",     color: "emerald", category: "문서 도구",   domain: "계약", path: contract_reason_path },
      { title: "견적서 일괄 문서생성",          desc: "견적서 1장을 업로드하면 사업계획서·소요예산·예정가격 조서를 한 번에 자동 생성합니다.", icon: "receipt_long",  color: "blue",    category: "자동화 도구", domain: "계약", path: quote_auto_path,                    badge: "NEW" },
      { title: "공문서 AI 작성 도우미",         desc: "기안문·협조문·통보문 등 공문서를 AI가 행정업무운영규정에 맞게 자동 작성합니다.", icon: "auto_awesome",      color: "indigo",  category: "자동화 도구", domain: "기타", path: official_document_path,             badge: "NEW" },
      { title: "4대보험 정산보험료 계산기",     desc: "연말정산·퇴직정산 보험료를 자동 계산합니다. 국민연금·건강·요양·고용·산재 합산까지.", icon: "health_and_safety", color: "blue", category: "계산기",   domain: "인사", path: insurance_calculator_path },
      { title: "예산 집행률 계산기",            desc: "예산 항목별 집행액을 입력하면 집행률·잔액·권장 기준 대비 현황을 즉시 파악합니다.", icon: "bar_chart",        color: "indigo",  category: "계산기",      domain: "예산", path: budget_execution_rate_path,         badge: "NEW" },
      { title: "예비비 한도 계산기",            desc: "예산 총액을 입력하면 지방재정법상 예비비 법정 한도(1%)와 적정 편성 금액을 자동 계산합니다.", icon: "savings", color: "amber", category: "계산기", domain: "예산", path: contingency_fund_path,             badge: "NEW" },
      { title: "초과근무수당 계산기",           desc: "월봉급액과 시간외·야간·휴일 근무시간을 입력하면 초과근무수당을 자동 계산합니다.",  icon: "schedule",          color: "indigo",  category: "계산기",      domain: "인사", path: overtime_calculator_path,           keywords: "시간외수당, 야간수당, 휴일수당" },
      { title: "연가일수 계산기",               desc: "임용일을 입력하면 재직 기간별 부여 연가일수, 잔여 연가, 연가보상비를 자동 계산합니다.", icon: "event_available", color: "emerald", category: "계산기",   domain: "인사", path: annual_leave_calculator_path },
      { title: "퇴직금 계산기",                desc: "재직기간과 기준 소득월액으로 공무원 퇴직수당을 자동 계산합니다.",                  icon: "savings",           color: "emerald", category: "계산기",      domain: "인사", path: severance_calculator_path,          badge: "NEW", keywords: "퇴직수당, 명예퇴직수당, 명퇴" },
      { title: "성과상여금 계산기",             desc: "성과등급(S·A·B)과 월봉급액으로 성과상여금을 자동 계산합니다.",                  icon: "emoji_events",      color: "amber",   category: "계산기",      domain: "인사", path: performance_bonus_calculator_path,  badge: "NEW", keywords: "성과급, 공공기관 성과급" },
      { title: "분할계약 판단 체크리스트",      desc: "계약 분할이 감사 지적 대상인지 5가지 기준으로 즉시 확인합니다.",                  icon: "rule",              color: "red",     category: "체크리스트",  domain: "계약", path: split_contract_checker_path,        badge: "NEW" },
      { title: "물가변동 조정금액 계산기",      desc: "지수조정률·품목조정률 방식으로 ESC 조정금액을 자동 계산합니다.",                  icon: "trending_up",       color: "indigo",  category: "계산기",      domain: "계약", path: price_adjustment_calculator_path,   badge: "NEW" },
      { title: "공무원 봉급 실수령액 계산기",   desc: "2026년 봉급표 기준 직급·호봉별 실수령액을 자동 계산합니다.",                     icon: "payments",          color: "blue",    category: "계산기",      domain: "인사", path: salary_calculator_path,             badge: "NEW" },
      { title: "공무원연금 예상 수령액 계산기", desc: "재직년수와 기준소득월액으로 예상 공무원연금 수령액을 자동 계산합니다.",             icon: "savings",           color: "violet",  category: "계산기",      domain: "인사", path: pension_calculator_path,            badge: "NEW" },
      { title: "공공기관 표준어 검사기",        desc: "행정안전부 「공공데이터 공통표준용어」 기준 비표준 행정 용어 자동 검사·교정 (PoC).", icon: "spellcheck",        color: "emerald", category: "검사기",      domain: "데이터", path: standard_term_checker_path,         badge: "NEW" },
      # unlisted: tools/index 카드 목록에는 없지만 라이브 운영 중인 도구 — 검색에만 노출 (목록 게재 여부는 별도 결정)
      { title: "예산 과목 분류 도우미",         desc: "지출 내용을 입력하면 적합한 세출예산 과목(목·세목)을 자동으로 추천합니다.",       icon: "category",          color: "indigo",  category: "자동화 도구", domain: "예산", path: budget_category_finder_path,        unlisted: true, keywords: "수도광열비, 특근매식비, 수용비, 공공요금, 세출예산, 목 세목" },
      { title: "공무원 수당 계산기",            desc: "정근수당·가족수당·명절휴가비·직급보조비를 수당 규정 기준으로 자동 계산합니다.",   icon: "payments",          color: "indigo",  category: "계산기",      domain: "인사", path: allowance_calculator_path,          unlisted: true, keywords: "가족수당, 정근수당, 명절휴가비, 직급보조비, 강사수당" },
      { title: "보조금 정산 체크리스트",        desc: "국고·지방보조금 정산 전 자가점검 항목을 감사 빈출 지적 기준으로 즉시 확인합니다.", icon: "checklist",         color: "amber",   category: "체크리스트",  domain: "예산", path: subsidy_settlement_checker_path,    unlisted: true, keywords: "e나라도움, 국고보조금, 지방보조금" },
      { title: "부서별 감사 대비 체크리스트",   desc: "담당 업무 유형별 감사 빈출 지적 기반 자가점검 체크리스트를 즉시 생성합니다.",     icon: "rule",              color: "red",     category: "체크리스트",  domain: "기타", path: audit_readiness_checker_path,       unlisted: true, keywords: "회계감사, 감사 지적, 자가점검" },
      { title: "계약 적법성 자가진단",          desc: "계약 단계별 감사원 빈출 지적사항을 체크리스트로 즉시 점검합니다.",                icon: "fact_check",        color: "emerald", category: "체크리스트",  domain: "계약", path: contract_legality_check_path,       unlisted: true, keywords: "감사 지적, 자가진단" },
      { title: "이월·전용 적법성 판단기",       desc: "예산 이월·전용 요건과 절차를 법령 기준으로 자동 판단합니다.",                     icon: "swap_horiz",        color: "amber",   category: "자동화 도구", domain: "예산", path: budget_transfer_checker_path,       unlisted: true, keywords: "명시이월, 사고이월, 계속비, 예산 전용" }
    ]
  end
end
