require "test_helper"

class ChatbotControllerTest < ActionDispatch::IntegrationTest
  # turbo_frame 요청만 검색 결과를 렌더 (직접 접근은 리다이렉트)
  TURBO_HEADERS = { "Turbo-Frame" => "search-results" }.freeze

  test "검색 결과에 도구가 포함된다 ('여비' → 여비계산기)" do
    get silmu_search_search_path(q: "여비"), headers: TURBO_HEADERS
    assert_response :success
    assert_select "[data-search-result='tool']"
    assert_match "여비계산기", response.body
  end

  test "도구 검색 결과가 tool_count 로 로깅된다" do
    assert_difference -> { SearchLog.count }, 1 do
      get silmu_search_search_path(q: "여비"), headers: TURBO_HEADERS
    end
    log = SearchLog.order(:created_at).last
    assert_operator log.tool_count, :>=, 1
    assert_not log.zero_result
  end

  test "직접 접근은 silmu-search 인덱스로 리다이렉트" do
    get silmu_search_search_path(q: "여비")
    assert_response :moved_permanently
  end

  test "레지스트리 도구가 검색된다 ('가족수당' → 공무원 수당 계산기)" do
    get silmu_search_search_path(q: "가족수당"), headers: TURBO_HEADERS
    assert_response :success
    assert_match "공무원 수당 계산기", response.body
  end

  # 2026-06-11 a827467: 전수 감사 통과로 종전 unlisted 6개 도구를 /tools 카드 목록에 게재(NEW 배지).
  # 종전 테스트는 "노출 안 됨"을 단언했으나 의도적 게재 후 stale → 현재 의도(노출됨)로 정정.
  test "감사 통과 도구(예산 과목 분류 도우미)는 tools 인덱스 카드 목록에 노출된다" do
    get tools_path
    assert_response :success
    assert_match "예산 과목 분류 도우미", response.body
  end

  # ---- P1.6 §21 바로 답 (Answer-First) ----

  # 픽스처가 아니라 테스트 안에서 만든다 — topics.yml 은 건드리면 안 된다(파일 상단 경고 참조).
  # 트랜잭션 롤백되므로 다른 테스트의 Topic.count 에 영향을 주지 않는다.
  def create_faq_topic!
    Topic.create!(
      name: "수의계약 한도 기준",
      slug: "test-answer-private-contract-limit",
      summary: "수의계약 한도 개요",
      keywords: "수의계약, 한도",
      published: true,
      view_count: 1,
      faqs: [ { "question" => "수의계약 한도는 얼마인가요?",
                "answer" => "물품·용역은 추정가격 2천만원 이하에서 1인 견적 수의계약이 가능합니다." } ]
    )
  end

  test "바로 답 카드가 실제로 렌더된다 (presenter 경계 포함)" do
    create_faq_topic!
    get silmu_search_search_path(q: "수의계약 한도"), headers: TURBO_HEADERS
    assert_response :success
    assert_select "#direct-answer-heading", text: "바로 답"
    assert_match "1인 견적 수의계약이 가능합니다", response.body
    assert_select "[data-search-result='answer']"
  end

  test "매칭 FAQ 가 없으면 바로 답 카드를 그리지 않는다 (빈 박스·지어낸 요약 금지)" do
    # FAQ 가 없는 기존 픽스처만 매칭되는 쿼리 — 카드가 나오면 안 된다.
    get silmu_search_search_path(q: "지방계약법 수의계약"), headers: TURBO_HEADERS
    assert_response :success
    assert_select "#direct-answer-heading", false
  end

  test "바로 답의 적용 대상은 presenter 경유로 렌더된다 (HIGH confidence 일 때만)" do
    # 이 테스트가 없으면 '적용 대상' 분기가 한 번도 실행되지 않아
    # presenter 대신 모델을 부르는 결함(topic.agency_labels = NoMethodError)이 통과해 버린다.
    create_faq_topic!.update!(
      target_agency: [ "LOCAL_GOVERNMENT" ],
      agency_scope_confidence: "HIGH"
    )
    get silmu_search_search_path(q: "수의계약 한도"), headers: TURBO_HEADERS
    assert_response :success
    assert_match "적용 대상: 지방자치단체", response.body
  end

  test "검색에 걸린 토픽이라도 질문과 무관한 FAQ 는 바로 답으로 승격되지 않는다" do
    # 핵심: 이 토픽은 "수의계약 한도" 로 **검색에는 걸린다**. 그런데 FAQ 질문은 전혀 다른 주제다.
    # 과반 게이트가 없으면 엉뚱한 FAQ 가 "바로 답" 으로 승격된다 — 그게 거짓 신뢰다.
    Topic.create!(
      name: "수의계약 한도 기준",
      slug: "test-answer-unrelated-faq",
      summary: "수의계약 한도 개요",
      keywords: "수의계약, 한도",
      published: true,
      view_count: 999,
      faqs: [ { "question" => "청렴서약서는 언제 받나요?", "answer" => "계약 체결 전에 받습니다." } ]
    )
    get silmu_search_search_path(q: "수의계약 한도"), headers: TURBO_HEADERS
    assert_response :success
    assert_select "#direct-answer-heading", false
    assert_no_match "계약 체결 전에 받습니다", response.body
  end

  test "결과 0건이면 다른 표현 안내와 요청 경로를 함께 준다 (막다른 길 금지)" do
    get silmu_search_search_path(q: "존재하지않는업무zzzqqq"), headers: TURBO_HEADERS
    assert_response :success
    assert_match "다른 표현으로 찾아보기", response.body
    assert_select "a[href=?]", feedback_path
  end

  test "검색어를 들고 오면 보조 탐색 블록을 접어 답을 먼저 보여준다 (§20)" do
    get silmu_search_path(q: "수의계약 한도")
    assert_response :success
    assert_no_match "금액으로 계약방법 찾기", response.body
    assert_no_match "주제별 상세 가이드", response.body
  end

  test "검색어 없이 들어오면 보조 탐색 블록은 그대로 남는다 (기능 삭제 아님)" do
    get silmu_search_path
    assert_response :success
    assert_match "금액으로 계약방법 찾기", response.body
    assert_match "주제별 상세 가이드", response.body
  end
end
