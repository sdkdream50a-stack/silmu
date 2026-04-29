# Created: 2026-04-29
# Phase B-1 #2 — 경기도교육청 감사사례집 2021 (4-2. 물품관리) 3건
# Source: https://www.goe.go.kr/resource/old/BBSMSTR_000000000102/BBS_202111190247253801.pdf
# 페이지 131~132, sector=edu, org_type=school

PDF_URL = "https://www.goe.go.kr/resource/old/BBSMSTR_000000000102/BBS_202111190247253801.pdf".freeze
PDF_SOURCE_BASE = {
  publisher: "경기도교육청 감사관실",
  publication: "감사사례집",
  year: 2021,
  url: PDF_URL,
  category: "물품관리"
}.freeze

cases = [
  {
    slug: "goe-2021-supplies-management-neglect",
    title: "물품관리 부적정 — 물품대장 미작성·재물조사 미실시",
    page: 131,
    category: "기타",
    severity: "보통",
    legal_basis: "공유재산 및 물품관리법, 같은법 시행령, 사학기관 재무·회계 규칙, 경기도교육비특별회계 소관 물품관리조례",
    issue: <<~ISSUE,
      ○○중학교에서 2010년 이후 보유 및 취득 물품에 대해 물품대장도 작성하지 않아 보유물품 현황을 알 수 없으며, 재물조사·물품 등록·출납·운용·불용 등 일체의 물품관리 관련 업무를 하지 않는 등 물품관리자·물품출납원·물품담당자의 책무를 해태함.
    ISSUE
    detail: <<~DETAIL,
      ## 사례 요약
      물품관리는 단순한 행정 절차가 아닌 학교 자산을 보전하는 핵심 업무. 물품대장 미작성 시:
      1. 분실·도난 발생 시 책임 추궁 불가
      2. 감가상각·내용연수 관리 불가
      3. 불용 처분 정당성 확보 불가
      4. 차기 회계연도 예산 편성 근거 부재

      ## 처분
      관련자 주의.
    DETAIL
    lesson: <<~LESSON
      ## 확인사항 (PDF §확인사항)
      - 사립학교는 「사학기관 재무회계 규칙」에 따라 물품관리자·물품출납원 및 물품사용자가 선량한 관리자 주의의무 부담.
      - 물품출납원은 물품관리자의 명령 없이 물품 출납 불가, 출납은 해당 물품 수급부에 결재 날인.
      - 물품관리자는 2년마다 정기적으로 학년도 말 기준 재물조사 실시 의무.

      ## silmu 실무 포인트
      에듀파인 물품 모듈 자동 등록만 신뢰하지 말 것 — 기증품·소액 비품·구매 외 취득(불용 양수 등)은 수동 등록 필요. 2년 주기 재물조사 시 누락 발견 가능.
    LESSON
  },
  {
    slug: "goe-2021-disposal-procedure-violation",
    title: "불용품 매각절차 부적정 — 10만원 초과 불용품 일반입찰 회피",
    page: 131,
    category: "수의계약",
    severity: "보통",
    legal_basis: "공유재산 및 물품관리법, 같은법 시행령, 경기도교육비특별회계 소관 물품관리조례",
    issue: <<~ISSUE,
      ○○초등학교 외 2교에서 처분단가 10만원을 초과하는 불용품을 매각하면서 일반입찰에 부치지 않고 수의계약을 체결해 매각함.
    ISSUE
    detail: <<~DETAIL,
      ## 사례 요약
      불용품 매각의 원칙은 일반입찰. 수의계약·경매로 매각 가능한 예외는:
      1. 처분단가 10만원 이하, 처분총액 500만원 이하
      2. 처분단가 500만원 이하, 처분총액 1천만원 이하의 불용농기계를 해당 지방자치단체 거주 농업인에게 매각

      ## 처분
      관련자 주의.
    DETAIL
    lesson: <<~LESSON
      ## 확인사항 (PDF §확인사항)
      - 처분단가 10만원 초과 불용품은 반드시 일반입찰. 예외는 위 2가지뿐.

      ## silmu 실무 포인트
      "잘 아는 업체에 한 번에 매각" 같은 편의는 즉시 회수 대상. 입찰 공고 1주일 + 최저 입찰가 산정만 거치면 절차상 안전.
    LESSON
  },
  {
    slug: "goe-2021-vehicle-management-failure",
    title: "공용차량 운영 및 관리 부적정 — 기관장 전용·운행일지 부실",
    page: 132,
    category: "기타",
    severity: "보통",
    legal_basis: "경기도교육비특별회계 소관 공용차량 관리 규칙",
    issue: <<~ISSUE,
      ○○직속기관에서 업무용 승용차량을 대부분 원장 전용차량으로 사용하였으며, 업무용 승용차량 운전원 정원이 감원되자 업무용 승합차량(버스) 운전원에게 추가로 승용차량 운전원 역할을 부여함. 차량 운행일지에서 목적지 대비 운행거리가 최소 30km~최대 195km까지 차이가 나며 경유지 미기입으로 실제 운행거리 검증 불가. ○○고등학교에서는 공용차량 관리대장·유류 수불대장·차량 정비대장·차량 운행일지를 기록·유지하지 않고 특정인이 차량키를 관리하며 사용함.
    ISSUE
    detail: <<~DETAIL,
      ## 사례 요약
      공용차량은 "여러 업무에 널리 활용되도록" 운영되어야 하며 기관장 전용 사용은 금지. 4종 필수 서류:
      1. 공용차량 관리대장
      2. 유류 수불대장
      3. 차량 정비대장
      4. 차량 운행일지 (목적지·경유지·운행거리 검증 가능 수준)

      ## 처분
      관련자 주의.
    DETAIL
    lesson: <<~LESSON
      ## 확인사항 (PDF §확인사항)
      - 업무용 공용차량을 정당한 사유 없이 개인 용도·업무 외 용도 사용 금지, 기관장 전용 사용 금지.
      - 4종 서류 비치·기록·유지 의무.

      ## silmu 실무 포인트
      운행일지에 "목적지 대비 운행거리 차이"가 30km 이상이면 경유지 누락이거나 사적 용도 가능성 — 운전원·결재권자 모두 검증 책임.
    LESSON
  }
]

cases.each do |c|
  audit = AuditCase.find_or_initialize_by(slug: c[:slug])
  audit.assign_attributes(
    title: c[:title],
    category: c[:category],
    severity: c[:severity],
    published: true,
    view_count: audit.view_count || 0,
    topic_slug: nil,
    legal_basis: c[:legal_basis],
    issue: c[:issue],
    detail: c[:detail],
    lesson: c[:lesson],
    sector: "edu",
    org_type: "school",
    source: PDF_SOURCE_BASE.merge(page: c[:page])
  )
  audit.save!
  puts "[OK] #{audit.slug} (page #{c[:page]})"
end

puts "[DONE] #{cases.size}건 시드 완료"
