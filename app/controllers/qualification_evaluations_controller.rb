# 적격심사·종합심사낙찰제 자동 채점기 컨트롤러
# - 적격심사: 추정가격 300억 미만 공사 (가격60+비가격40, 95점 이상 적격)
# - 종합심사낙찰제(종심제): 추정가격 300억 이상 공사 (가격50+시공실적20+시공능력15+경영상태10+사회책임5)

class QualificationEvaluationsController < ApplicationController
  # 종심제 배점 구조 (조달청/지자체 공통 기준)
  COMPREHENSIVE_SCORE_STRUCTURE = {
    price:           { name: "가격",           max: 50, desc: "입찰금액 / 예정가격 비율 기준" },
    construction:    { name: "시공실적",        max: 20, desc: "최근 10년 시공실적 평가" },
    capacity:        { name: "시공능력",        max: 15, desc: "시공능력평가액 기준 항목" },
    management:      { name: "경영상태",        max: 10, desc: "부채비율·유동비율 등 재무지표" },
    social:          { name: "사회적책임",      max: 5,  desc: "고용·상생협력·안전관리 등" }
  }.freeze

  def index
    set_meta_tags(
      title: "적격심사·종심제 자동 채점기 — 가격·비가격 점수 자동 계산",
      description: "공사·용역 입찰의 적격심사(300억 미만)와 종합심사낙찰제(300억 이상) 점수를 자동으로 계산합니다. 공사금액 입력 시 적용 제도를 자동 판별합니다.",
      keywords: "적격심사, 종심제, 종합심사낙찰제, 가격점수, 비가격점수, 낙찰자 선정, 입찰평가",
      og: {
        title: "적격심사·종심제 자동 채점기 — 실무.kr",
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
    floor_rate      = params[:floor_rate]&.to_f || 89.745
    price_max       = project_type == "construction" ? 60 : 70
    non_price_max   = project_type == "construction" ? 40 : 30

    bidders = parse_bidders_from_params
    bidders_with_scores = calculate_price_scores(bidders, estimated_price, floor_rate, price_max)
    bidders_with_total  = calculate_total_scores(bidders_with_scores, price_max, non_price_max)
    qualified_bidders   = bidders_with_total.select { |b| b[:total_score_100] >= 95 }
    winner              = qualified_bidders.min_by { |b| b[:bid_price] }

    render json: {
      mode: "qualification",
      bidders: bidders_with_total,
      qualified_bidders: qualified_bidders,
      winner: winner,
      metadata: {
        project_type: project_type,
        estimated_price: estimated_price,
        floor_rate: floor_rate,
        price_max: price_max,
        non_price_max: non_price_max
      }
    }
  end

  # POST /qualification-evaluations/comprehensive (종합심사낙찰제)
  def comprehensive
    estimated_price = params[:estimated_price].to_f
    floor_rate      = params[:floor_rate]&.to_f || 89.745
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

    floor_price   = estimated_price * (floor_rate / 100.0)
    valid_bidders = bidders.select { |b| b[:bid_price] >= floor_price }
    lowest_price  = valid_bidders.map { |b| b[:bid_price] }.min || 0

    scored = valid_bidders.map do |b|
      price_score = lowest_price > 0 ? (50.0 * lowest_price / b[:bid_price]).round(2) : 0
      non_price   = b[:construction] + b[:capacity] + b[:management] + b[:social]
      total       = (price_score + non_price).round(2)

      b.merge(
        price_score: price_score,
        non_price_total: non_price.round(2),
        total_score: total,
        is_qualified: total >= 92,   # 종심제 적격 기준: 92점 이상
        floor_price: floor_price
      )
    end.sort_by { |b| [ -b[:total_score], b[:bid_price] ] }

    # 종심제 낙찰자: 적격자(92점 이상) 중 최고점, 동점 시 최저가
    winner = scored.select { |b| b[:is_qualified] }.first

    render json: {
      mode: "comprehensive",
      bidders: scored,
      winner: winner,
      metadata: {
        estimated_price: estimated_price,
        floor_rate: floor_rate,
        floor_price: floor_price,
        score_structure: COMPREHENSIVE_SCORE_STRUCTURE
      }
    }
  end

  private

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

  def calculate_price_scores(bidders, estimated_price, floor_rate, price_max)
    floor_price   = estimated_price * (floor_rate / 100.0)
    valid_bidders = bidders.select { |b| b[:bid_price] >= floor_price }
    lowest_price  = valid_bidders.map { |b| b[:bid_price] }.min

    valid_bidders.map do |bidder|
      price_score = if bidder[:bid_price] == lowest_price
                      price_max
      else
                      price_max * (lowest_price / bidder[:bid_price])
      end
      bidder.merge(price_score: price_score.round(2), is_valid: true, floor_price: floor_price)
    end
  end

  def calculate_total_scores(bidders, price_max, non_price_max)
    bidders.map do |bidder|
      total_score     = bidder[:price_score] + bidder[:non_price_score]
      total_max       = price_max + non_price_max
      total_score_100 = (total_score / total_max * 100).round(2)
      bidder.merge(
        total_score:     total_score.round(2),
        total_score_100: total_score_100,
        is_qualified:    total_score_100 >= 95
      )
    end.sort_by { |b| -b[:total_score_100] }
  end
end
