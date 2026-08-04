require "test_helper"

# 2026-08-04 도구 정확성 P0 교정 — 컨트롤러 경로 회귀 테스트.
class ToolAccuracyEndpointsTest < ActionDispatch::IntegrationTest
  # ── 적격심사: 경쟁자 최저가에 종속된 가격점수를 내보내던 결함 ──
  test "적격심사는 가격점수를 산출하지 않고 사유를 밝힌다" do
    post "/qualification-evaluations/evaluate", params: {
      project_type: "construction", estimated_price: 100_000_000, floor_rate: 89.745,
      bidder_count: 2,
      bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 35,
      bidder_2_name: "B", bidder_2_price: 95_000_000, bidder_2_non_price: 38
    }
    assert_response :success
    body = JSON.parse(response.body)

    assert body["score_unavailable"], "점수 미산출 사실이 응답에 표시되어야 한다"
    assert_nil body["winner"], "점수를 못 내면 낙찰자도 단정하면 안 된다"
    assert body["notice"].present?
    body["bidders"].each do |b|
      assert_nil b["price_score"], "가격점수는 산출하지 않는다"
      assert_nil b["is_qualified"], "적격 여부를 단정하면 안 된다"
      assert b["bid_ratio"].present?, "입찰률은 참고값으로 제공한다"
    end
  end

  test "적격심사 결과는 경쟁자 구성이 바뀌어도 같은 입찰가의 값이 달라지지 않는다" do
    common = { project_type: "construction", estimated_price: 100_000_000, floor_rate: 89.745 }

    post "/qualification-evaluations/evaluate", params: common.merge(
      bidder_count: 2,
      bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 35,
      bidder_2_name: "B", bidder_2_price: 95_000_000, bidder_2_non_price: 38
    )
    with_rival = JSON.parse(response.body)["bidders"].find { |b| b["name"] == "B" }

    post "/qualification-evaluations/evaluate", params: common.merge(
      bidder_count: 1,
      bidder_1_name: "B", bidder_1_price: 95_000_000, bidder_1_non_price: 38
    )
    alone = JSON.parse(response.body)["bidders"].find { |b| b["name"] == "B" }

    assert_equal with_rival["bid_ratio"], alone["bid_ratio"],
      "같은 입찰가는 경쟁자 유무와 무관하게 같은 값이어야 한다"
    assert_nil with_rival["price_score"]
    assert_nil alone["price_score"]
  end

  # ── 추정가격: 공사 종류 없이 종합공사 4억을 단정하던 결함 ──
  test "공사는 종류를 지정하지 않으면 수의계약 가능 여부를 단정하지 않는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", material: 300_000_000
    }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"], "계산이 실패하면 안 된다: #{body['error']}"
    assert_equal 300_000_000, body.dig("result", "base_amount"),
      "원가항목이 0으로 떨어지면 모든 공사가 수의계약 가능으로 표시된다"

    pc = body.dig("result", "private_contract")
    assert pc["undetermined"], "종류 미지정 시 판단 보류여야 한다"
    assert_nil pc["available"]
    assert_includes pc["note"], "전문공사 2억"
  end

  test "전문공사 3억은 수의계약 한도를 넘는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", construction_type: "special",
      material: 300_000_000
    }, as: :json
    body = JSON.parse(response.body)
    assert body["success"], "계산이 실패하면 안 된다: #{body['error']}"

    pc = body.dig("result", "private_contract")
    assert_equal 200_000_000, pc["threshold"]
    assert_equal false, pc["available"]
    assert_equal "입찰", pc.dig("estimate_requirement", "type"),
      "수의계약 불가인데 견적요건이 '2인 이상 견적'이면 모순이다"
  end

  test "종합공사 3억은 수의계약 가능이고 견적요건도 모순되지 않는다" do
    post "/estimated-prices/calculate", params: {
      contract_type: "construction", construction_type: "general",
      material: 300_000_000
    }, as: :json
    pc = JSON.parse(response.body).dig("result", "private_contract")
    assert_equal true, pc["available"]
    assert_equal "2인 이상 견적", pc.dig("estimate_requirement", "type"),
      "1억 초과라는 이유로 '입찰'이 나오면 물품 기준을 공사에 잘못 적용한 것이다"
  end

  # ── HWPX: 클라이언트가 보낸 결과를 그대로 문서화하던 결함 ──
  test "HWPX는 클라이언트가 보낸 연가일수를 신뢰하지 않는다" do
    post "/tools/annual-leave/hwpx", params: {
      hire_date: "2025-01-01", ref_year: 2026, used_leave: 0,
      granted_leave: "999일", remaining_leave: "999일"   # 위조 시도
    }
    # 폰트 미설치 등으로 생성 자체가 실패할 수 있으나, 어떤 경우에도
    # 위조된 999가 채택되어서는 안 된다. 서버 재계산 결과는 12일이다.
    assert_includes [ 200, 422 ], response.status
    assert_equal 12, PdfExportService.annual_leave_data(
      hire_date: "2025-01-01", ref_year: 2026, used_leave: 0
    )[:granted]
  end

  test "HWPX는 임용일이 잘못되면 생성하지 않는다" do
    post "/tools/annual-leave/hwpx", params: { hire_date: "2026/01/01", ref_year: 2026 }
    assert_response :unprocessable_entity
  end

  # ── ads.txt: 수익화하지 않으므로 승인 판매자 선언이 없어야 한다 ──
  test "ads.txt는 더 이상 제공하지 않는다" do
    get "/ads.txt"
    assert_response :not_found
  end

  # ── 적격심사 대상 판정: 기준은 예정가격이 아니라 추정가격 ──
  QUAL_BASE = {
    project_type: "construction", floor_rate: 89.745,
    bidder_count: 1, bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 35
  }.freeze

  test "추정가격 300억 이상 공사는 적격심사로 산출하지 않는다" do
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 33_000_000_000, presumed_price: 30_000_000_000)

    assert_response :unprocessable_entity
    assert_match(/종합심사낙찰제/, JSON.parse(response.body)["error"])
  end

  test "예정가격이 300억을 넘어도 추정가격이 300억 미만이면 막지 않는다" do
    # 예정가격은 부가세를 포함해 추정가격보다 크다. 예정가격으로 판정하면 이 정당한 건이 오차단된다.
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 30_800_000_000, presumed_price: 28_000_000_000)

    assert_response :success
  end

  test "종심제는 공사 대상이므로 용역은 추정가격 300억 이상이어도 막지 않는다" do
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(project_type: "service", estimated_price: 33_000_000_000, presumed_price: 31_000_000_000)

    assert_response :success
  end

  test "통과기준 구간은 예정가격이 아니라 추정가격으로 갈린다" do
    # 두 값은 서로 환산되지 않으므로 같은 건에서 100억 경계를 사이에 두고 갈릴 수 있다.
    # 그런 조합이라야 구간 판정이 어느 값을 쓰는지 판별된다.
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 10_200_000_000, presumed_price: 9_500_000_000)
    assert_equal 95, JSON.parse(response.body)["metadata"]["pass_score"],
      "예정가격이 102억이어도 추정가격 95억이면 100억 미만 구간(95점)이다"

    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 11_200_000_000, presumed_price: 10_500_000_000)
    assert_equal 92, JSON.parse(response.body)["metadata"]["pass_score"],
      "추정가격 105억은 100억 이상 구간(92점)이다"
  end

  test "통과기준 100억 경계는 이상·미만으로 갈린다" do
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 11_000_000_000, presumed_price: 9_999_999_999)
    assert_equal 95, JSON.parse(response.body)["metadata"]["pass_score"], "100억 미만은 95점"

    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 11_000_000_000, presumed_price: 10_000_000_000)
    assert_equal 92, JSON.parse(response.body)["metadata"]["pass_score"], "정확히 100억은 92점 구간"
  end

  test "종심제 300억 경계는 이상·미만으로 갈린다" do
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 33_000_000_000, presumed_price: 29_999_999_999)
    assert_response :success, "300억 미만은 적격심사 대상이다"

    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 33_000_000_000, presumed_price: 30_000_000_000)
    assert_response :unprocessable_entity, "정확히 300억은 종심제 대상이다"
  end

  test "추정가격을 받지 못하면 공사 통과기준을 단정하지 않는다" do
    post "/qualification-evaluations/evaluate", params: QUAL_BASE.merge(estimated_price: 16_500_000_000)

    assert_response :success
    assert_nil JSON.parse(response.body)["metadata"]["pass_score"],
      "구간 기준값이 없으면 95/92 중 어느 쪽도 단정하면 안 된다"
  end

  # 서버가 92점을 산출해도 화면 안내가 95점 고정이면 사용자는 틀린 값을 본다.
  # 파일을 열거하지 않고 뷰 전체에서 파생 검사한다.
  test "적격심사 화면 안내는 서버 통과기준과 어긋나지 않는다" do
    view = Rails.root.join("app/views/qualification_evaluations/index.html.erb").read
    # 공사 블록만 본다. 용역은 서버도 95점 고정이라 같은 문구가 정상값이다.
    construction_block = view[/🏗️ 공사(.*?)💼 용역/m]
    assert construction_block.present?, "공사 안내 블록을 찾지 못했다 — 검사가 통과한 게 아니라 대상을 놓친 것이다"

    assert_no_match(/적격 기준: <strong>95점 이상<\/strong>/, construction_block,
      "공사 통과기준을 95점으로 고정 고지하면 100억 이상 구간(92점)과 어긋난다")
    # 92점이 어딘가에 있기만 하면 통과하는 검사는 구간이 틀리게 바뀌어도 놓친다 → 구간과 묶어서 고정한다.
    assert_match(/100억 미만.*95점/m, construction_block, "100억 미만 구간이 95점으로 고지돼야 한다")
    assert_match(/100억 이상 300억 미만.*92점/m, construction_block,
      "92점 구간은 상한(300억)까지 명시해야 종심제 구간과 오독되지 않는다")

    # 서버 산출과 실제로 대조한다 — 안내 문구만 고치고 서버가 다른 값을 내면 여전히 어긋난다.
    ctrl = QualificationEvaluationsController.new
    assert_equal 92, ctrl.send(:qualification_pass_score, "construction", 15_000_000_000)
    assert_equal 95, ctrl.send(:qualification_pass_score, "construction", 9_000_000_000)
  end

  test "적격심사 초기 화면은 특정 낙찰하한율을 권하지 않는다" do
    get qualification_evaluation_path
    assert_response :success

    assert_select 'form[data-action*="input->qualification-evaluation#inputChanged"]', count: 1,
      message: "동적 업체 입력을 포함한 모든 산출 입력 변경이 이전 응답을 무효화해야 한다"
    assert_select 'input[name="floor_rate"]' do |inputs|
      assert_no_match(/89\.745/, inputs.first["placeholder"].to_s)
    end
    assert_select '[data-qualification-evaluation-target="floorRateNote"]' do |notes|
      assert_no_match(/89\.745/, notes.first.text)
      assert_match(/공고문/, notes.first.text)
    end
  end

  # 서버는 종심제 총점·적격 여부·낙찰자를 산출하지 않는다(별표 산식 미지원).
  # 화면이 이를 확정값처럼 고지하면 P0에서 차단한 미지원 산출이 안내로 되살아난다.
  # 파일을 열거하지 않고 종심제를 다루는 표면 전체에서 파생 검사한다.
  # 화면에 실제로 보이는 텍스트 조각만 남긴다.
  # 인라인 강조(<strong> 등)는 문장을 끊지 않는다 — 끊으면 같은 문장 안의 단서를 놓쳐 오탐이 난다.
  INLINE_TAGS = %w[strong b em i span small u code br].freeze

  def rendered_segments(html)
    text = html.gsub(%r{</?(?:#{INLINE_TAGS.join('|')})\b[^>]*>}i, "")
    text.gsub(/<[^>]*>/, "\n").split("\n").map(&:strip).reject(&:empty?)
  end

  SCORE_ITEMS = %w[가격 시공실적 시공능력 경영상태 사회적책임].freeze

  # "가격50", "가격: 50점", "= 100 점"처럼 표기를 바꿔도 같은 단정이다.
  # 정확 문구가 아니라 "배점 항목이 숫자와 함께 둘 이상 나열되는가"로 판정한다.
  def score_claim?(segment)
    return true if segment =~ /총점\s*[::(（\[]?\s*\d+\s*점/
    return true if segment =~ /=\s*\d+\s*점/

    # 괄호 표기("가격(50점)")도 같은 단정이다 → 숫자 앞의 여는 기호를 허용한다.
    SCORE_ITEMS.count { |item| segment =~ /#{item}\s*[::(（\[]?\s*\d/ } >= 2
  end

  # 서버가 산출하지 않기로 한 값이 응답 어디에도 실려 있으면 안 된다.
  # bidders만 훑으면 top-level winner로 되살아나는 걸 놓친다 → 응답 전체를 파생 순회한다.
  UNSUPPORTED_SCORE_KEYS = %w[total_score total_score_100 price_score is_qualified winner].freeze

  def unsupported_score_values(node, path = "")
    case node
    when Hash
      node.flat_map do |key, value|
        here = path.empty? ? key.to_s : "#{path}.#{key}"
        hit = UNSUPPORTED_SCORE_KEYS.include?(key.to_s) && !value.nil? ? [ [ here, value ] ] : []
        hit + unsupported_score_values(value, here)
      end
    when Array
      node.each_with_index.flat_map { |value, i| unsupported_score_values(value, "#{path}[#{i}]") }
    else
      []
    end
  end

  test "종심제 화면은 산출하지 않는 총점 기준을 단정하지 않는다" do
    # 소스 문자열 검사는 동적 보간(<%= info[:max] %>)이나 표기 변경으로 뚫린다.
    # **렌더된 화면**을 받아서, 배점·총점 숫자가 나오는 텍스트 조각마다
    # 참고·공고문 표시가 붙어 있어야 한다는 불변조건으로 검사한다.
    get qualification_evaluation_path
    assert_response :success

    rendered_segments(response.body).each do |seg|
      next unless score_claim?(seg)
      assert_match(/참고|공고문/, seg,
        "미확인 종심제 배점·총점을 참고 표시 없이 고지하고 있다 — #{seg[0, 90]}")
    end

    # 실제로 서버가 산출하지 않는지도 함께 고정한다 — 문구만 고치고 서버가 값을 내면 반대로 어긋난다.
    post "/qualification-evaluations/comprehensive", params: {
      estimated_price: 40_000_000_000, floor_rate: 89.745, bidder_count: 1,
      bidder_1_name: "A", bidder_1_price: 38_000_000_000,
      bidder_1_construction: 20, bidder_1_capacity: 15, bidder_1_management: 10, bidder_1_social: 5
    }
    assert_response :success
    leaked = unsupported_score_values(JSON.parse(response.body))
    assert_empty leaked,
      "종심제는 총점·적격·낙찰자를 산출하지 않는다 — 응답에 되살아난 값: #{leaked.inspect}"
  end

  test "적격심사도 총점·적격·낙찰자를 응답에 싣지 않는다" do
    post "/qualification-evaluations/evaluate",
      params: QUAL_BASE.merge(estimated_price: 10_000_000_000, presumed_price: 9_000_000_000)

    assert_response :success
    leaked = unsupported_score_values(JSON.parse(response.body))
    assert_empty leaked,
      "가격평점을 산출하지 않으므로 총점·적격·낙찰자도 실으면 안 된다 — #{leaked.inspect}"
  end
end
