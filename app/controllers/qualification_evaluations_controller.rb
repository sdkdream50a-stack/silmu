# 적격심사·종합심사낙찰제 입찰률 확인 컨트롤러 (가격평점은 예규 별표 산식이라 미산출)
# - 적격심사: 추정가격 300억 미만 공사 (가격60+비가격40, 95점 이상 적격)
# - 종합심사낙찰제(종심제): 추정가격 300억 이상 공사 (가격50+시공실적20+시공능력15+경영상태10+사회책임5)

class QualificationEvaluationsController < ApplicationController
  # 종심제 배점 구조 — **참고값**이다. 1차출처(발주기관 심사기준표)로 확인되지 않았고
  # 발주기관·공사유형별로 달라지므로, 입력 상한으로 강제하거나 확정 배점으로 고지하지 않는다.
  # 이 상수는 화면에 참고 배점을 보여주는 용도로만 쓴다(총점·적격 여부·낙찰자는 산출하지 않는다).
  COMPREHENSIVE_SCORE_STRUCTURE = {
    price:           { name: "가격",           max: 50, desc: "입찰금액 / 예정가격 비율 기준" },
    construction:    { name: "시공실적",        max: 20, desc: "최근 10년 시공실적 평가" },
    capacity:        { name: "시공능력",        max: 15, desc: "시공능력평가액 기준 항목" },
    management:      { name: "경영상태",        max: 10, desc: "부채비율·유동비율 등 재무지표" },
    social:          { name: "사회적책임",      max: 5,  desc: "고용·상생협력·안전관리 등" }
  }.freeze

  def index
    set_meta_tags(
      title: "적격심사·종심제 입찰률 확인 — 낙찰하한율 미달 여부 점검",
      description: "공사·용역 입찰의 낙찰하한율 미달 여부와 입찰률을 확인합니다. 가격평점은 행안부 예규 별표의 금액구간별 산식이라 이 도구에서 산출하지 않으며, 적격 여부와 낙찰자는 공고문의 적격심사 세부기준으로 판단해야 합니다.",
      keywords: "적격심사, 종심제, 종합심사낙찰제, 가격점수, 비가격점수, 낙찰자 선정, 입찰평가",
      og: {
        title: "적격심사·종심제 입찰률 확인 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp"
      }
    )
    @comprehensive_structure = COMPREHENSIVE_SCORE_STRUCTURE
  end

  # POST /qualification-evaluations/evaluate (적격심사)
  def evaluate
    project_type    = params[:project_type]
    estimated_price = params[:estimated_price].to_f
    # 낙찰하한가의 기준은 예정가격이고, 적격심사·종심제 대상 판단과 통과기준 구간의 기준은 추정가격이다.
    # 두 값은 법적 정의와 산정 단계가 달라(추정가격은 부가세 제외 사전 산정치) 서로 환산되지 않는다.
    # 한 값으로 겸용하면 대상 판정이 어긋나므로 별도 입력으로 받는다.
    presumed_price  = params[:presumed_price].to_f
    # 빈 문자열은 to_f가 0.0으로 만들어 모든 투찰이 "하한 이상"이 된다 → 미달 확인이 무력화된다.
    floor_rate      = parse_floor_rate(params[:floor_rate])
    return render json: { error: FLOOR_RATE_REQUIRED }, status: :unprocessable_entity if floor_rate.nil?
    # 예정가격이 0이면 하한가도 0이 되어 모든 투찰이 "하한 이상"으로 나온다.
    return render json: { error: ESTIMATED_PRICE_REQUIRED }, status: :unprocessable_entity if estimated_price <= 0
    # 추정가격 300억 이상 공사는 종합심사낙찰제 대상이라 적격심사 기준을 적용하면 안 된다.
    if project_type == "construction" && presumed_price >= COMPREHENSIVE_THRESHOLD
      return render json: { error: COMPREHENSIVE_REQUIRED }, status: :unprocessable_entity
    end
    price_max       = project_type == "construction" ? 60 : 70
    non_price_max   = project_type == "construction" ? 40 : 30

    # 적격심사 통과기준 추정가격 차등 — 행안부 예규 「지방자치단체 입찰시 낙찰자 결정기준」
    # 제2장의1 시설공사 적격심사 세부기준 제6절(낙찰자 결정): 공사 100억 미만 95점 / 100억 이상 300억 미만 92점.
    # 예규 호수는 개정마다 바뀌므로 인용하지 않는다(장·절로 고정).
    pass_score = qualification_pass_score(project_type, presumed_price)

    bidders = parse_bidders_from_params
    bidders_with_scores = calculate_price_scores(bidders, estimated_price, floor_rate, price_max)
    bidders_with_total  = calculate_total_scores(bidders_with_scores, price_max, non_price_max, pass_score)

    render json: {
      mode: "qualification",
      bidders: bidders_with_total,
      qualified_bidders: [],
      winner: nil,
      score_unavailable: true,
      notice: "입찰가격 평점은 행안부 예규 별표의 금액구간별 산식으로 산출해야 하며, " \
              "이 도구는 해당 별표·금액구간 입력을 지원하지 않아 점수를 산출하지 않습니다. " \
              "낙찰하한율 미달 여부와 입찰률만 참고하시고, 적격 여부는 공고문의 적격심사 세부기준으로 판단하세요.",
      metadata: {
        project_type: project_type,
        estimated_price: estimated_price,
        presumed_price: presumed_price,
        floor_rate: floor_rate,
        price_max: price_max,
        non_price_max: non_price_max,
        pass_score: pass_score
      }
    }
  end

  # POST /qualification-evaluations/comprehensive (종합심사낙찰제)
  def comprehensive
    estimated_price = params[:estimated_price].to_f
    floor_rate      = parse_floor_rate(params[:floor_rate])
    return render json: { error: FLOOR_RATE_REQUIRED }, status: :unprocessable_entity if floor_rate.nil?
    # 예정가격이 0이면 하한가도 0이 되어 모든 투찰이 "하한 이상"으로 나온다.
    return render json: { error: ESTIMATED_PRICE_REQUIRED }, status: :unprocessable_entity if estimated_price <= 0

    bidder_count    = params[:bidder_count].to_i

    bidders = (1..bidder_count).map do |i|
      {
        name:         params["bidder_#{i}_name"].to_s,
        bid_price:    params["bidder_#{i}_price"].to_f,
        construction: params["bidder_#{i}_construction"].to_f, # 시공실적 점수
        capacity:     params["bidder_#{i}_capacity"].to_f,     # 시공능력 점수
        management:   params["bidder_#{i}_management"].to_f,   # 경영상태 점수
        social:       params["bidder_#{i}_social"].to_f        # 사회적책임 점수
      }
    end

    floor_price = estimated_price * (floor_rate / 100.0)

    # 적격심사와 같은 이유로 가격점수를 산출하지 않는다 —
    # 종합심사낙찰제 입찰금액 평점도 예규 별표 산식을 따르며, 최저가 대비 비율이 아니다.
    # 비가격(시공실적·능력·경영·사회적책임) 합계만 그대로 제공한다.
    scored = bidders.map do |b|
      non_price = b[:construction] + b[:capacity] + b[:management] + b[:social]
      below = floor_price > 0 && b[:bid_price] < floor_price

      b.merge(
        price_score: nil,
        price_score_unavailable: true,
        bid_ratio: estimated_price > 0 ? (b[:bid_price] / estimated_price * 100).round(3) : nil,
        below_floor: below,
        is_valid: !below,
        non_price_total: non_price.round(2),
        total_score: nil,
        is_qualified: nil,
        floor_price: floor_price
      )
    end.sort_by { |b| b[:bid_price] }

    render json: {
      mode: "comprehensive",
      bidders: scored,
      winner: nil,
      score_unavailable: true,
      notice: "입찰금액 평점은 예규 별표의 산식으로 산출해야 하며 이 도구는 이를 지원하지 않습니다. " \
              "비가격 평점 합계와 낙찰하한율 미달 여부만 참고하시고, 낙찰자 판단은 공고문 기준으로 하세요.",
      metadata: {
        estimated_price: estimated_price,
        floor_rate: floor_rate,
        floor_price: floor_price,
        score_structure: COMPREHENSIVE_SCORE_STRUCTURE
      }
    }
  end

  ESTIMATED_PRICE_REQUIRED = "예정가격을 입력하세요. 예정가격이 없으면 낙찰하한가를 산출할 수 없어 " \
                             "미달 여부를 판단할 수 없습니다.".freeze

  FLOOR_RATE_REQUIRED = "낙찰하한율을 입력하세요. 계약 종류·금액구간·공고문에 따라 다르므로 " \
                        "공고문에 적힌 값을 그대로 넣어야 미달 여부를 확인할 수 있습니다.".freeze

  # 종합심사낙찰제 대상 기준 (지방계약법 시행령 제42조의3) — 추정가격 300억원 이상 공사
  COMPREHENSIVE_THRESHOLD = 30_000_000_000

  COMPREHENSIVE_REQUIRED = "추정가격 300억원 이상 공사는 종합심사낙찰제(종심제) 대상이라 " \
                           "적격심사 기준을 적용할 수 없습니다. 상단의 「종합심사낙찰제」 탭으로 전환해 확인하세요.".freeze

  private

  # 낙찰하한율은 이 도구의 유일한 판정 기준이다. 비었거나 범위를 벗어나면 추정하지 않고 거부한다.
  def parse_floor_rate(raw)
    value = raw.to_s.strip
    return nil if value.empty?

    rate = Float(value, exception: false)
    return nil if rate.nil? || rate <= 0 || rate > 100

    rate
  end

  def parse_bidders_from_params
    bidder_count = params[:bidder_count].to_i
    (1..bidder_count).map do |i|
      {
        name:            params["bidder_#{i}_name"],
        bid_price:       params["bidder_#{i}_price"].to_f,
        non_price_score: params["bidder_#{i}_non_price"].to_f
      }
    end
  end

  # ⚠️ 공식 가격평점 산식이 아니다.
  # 지방계약 적격심사의 입찰가격 평점은 행안부 예규 별표의 **금액구간별 산식**으로 산출하며
  # 입찰자 자신의 입찰률(입찰가격/예정가격)만으로 결정된다. 아래 상대평가(최저가 대비 비율)는
  # 경쟁자 구성이 바뀌면 같은 입찰가의 점수가 달라져 실제 제도와 어긋난다.
  # 별표·금액구간 입력이 없는 상태에서 숫자를 내놓으면 입찰 판단을 오도하므로 산출하지 않는다.
  def calculate_price_scores(bidders, estimated_price, floor_rate, price_max)
    floor_price = estimated_price * (floor_rate / 100.0)

    # 하한 미달 업체를 목록에서 빼면 이 도구의 유일한 기능(미달 여부 확인)이 불가능해진다.
    # 제거하지 않고 below_floor로 표시해 사용자가 직접 확인하게 한다.
    bidders.map do |bidder|
      below = floor_price > 0 && bidder[:bid_price] < floor_price
      bidder.merge(
        price_score: nil,
        price_score_unavailable: true,
        bid_ratio: estimated_price > 0 ? (bidder[:bid_price] / estimated_price * 100).round(3) : nil,
        below_floor: below,
        is_valid: !below,
        floor_price: floor_price
      )
    end
  end

  # 가격평점을 산출하지 않으므로 총점·적격 여부도 확정할 수 없다.
  # 비가격 평점만 그대로 돌려주고, 판정은 공고문 기준으로 하도록 남긴다.
  def calculate_total_scores(bidders, price_max, non_price_max, pass_score = 95)
    bidders.map do |bidder|
      bidder.merge(
        total_score:     nil,
        total_score_100: nil,
        is_qualified:    nil,
        score_unavailable: true
      )
    end.sort_by { |b| b[:bid_price] }
  end

  # 적격심사 통과기준 (예규 「지방자치단체 입찰시 낙찰자 결정기준」 제2장의1 제6절):
  # 공사 추정가격 100억 미만 95점 / 100억 이상 300억 미만 92점. 물품·용역은 별도 기준(현행 95점 유지).
  # 공사는 구간이 추정가격으로 갈리므로, 추정가격을 받지 못하면 점수를 단정하지 않고 nil을 돌려준다(공고문 확인 안내).
  def qualification_pass_score(project_type, presumed_price)
    return 95 unless project_type == "construction"
    return nil if presumed_price <= 0

    presumed_price >= 10_000_000_000 ? 92 : 95
  end
end
