# Created: 2026-02-22
# 적격심사 자동 채점기 컨트롤러

class QualificationEvaluationsController < ApplicationController
  def index
    set_meta_tags(
      title: "적격심사 자동 채점기 — 가격·비가격 점수 자동 계산",
      description: "2억원 이상 공사·용역 입찰의 적격심사 점수를 자동으로 계산합니다. 가격점수와 비가격점수를 입력하면 95점 기준 적격 여부를 즉시 판정하고, 낙찰자를 자동 선정합니다. 지방계약법 시행령 제42조의2 기준.",
      keywords: "적격심사, 적격심사표, 가격점수, 비가격점수, 낙찰자 선정, 입찰평가",
      og: {
        title: "적격심사 자동 채점기 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    )
  end

  def evaluate
    # 입찰 기본 정보
    project_type = params[:project_type] # "construction" or "service"
    estimated_price = params[:estimated_price].to_f
    floor_rate = params[:floor_rate]&.to_f || 89.745 # 낙찰하한율 (공사 기본값)

    # 배점 구조 결정
    price_max = project_type == "construction" ? 60 : 70
    non_price_max = project_type == "construction" ? 40 : 30

    # 업체별 입찰 정보
    bidders = parse_bidders_from_params

    # 가격점수 계산
    bidders_with_scores = calculate_price_scores(bidders, estimated_price, floor_rate, price_max)

    # 총점 계산 및 100점 환산
    bidders_with_total = calculate_total_scores(bidders_with_scores, price_max, non_price_max)

    # 적격 여부 판정 (95점 이상)
    qualified_bidders = bidders_with_total.select { |b| b[:total_score_100] >= 95 }

    # 낙찰자 선정 (적격자 중 최저가)
    winner = qualified_bidders.min_by { |b| b[:bid_price] }

    render json: {
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

  private

  def parse_bidders_from_params
    bidder_count = params[:bidder_count].to_i

    (1..bidder_count).map do |i|
      {
        name: params["bidder_#{i}_name"],
        bid_price: params["bidder_#{i}_price"].to_f,
        non_price_score: params["bidder_#{i}_non_price"].to_f
      }
    end
  end

  def calculate_price_scores(bidders, estimated_price, floor_rate, price_max)
    # 낙찰하한율 적용 예정가격 계산
    floor_price = estimated_price * (floor_rate / 100.0)

    # 유효 입찰가 필터링 (낙찰하한율 미만은 무효)
    valid_bidders = bidders.select { |b| b[:bid_price] >= floor_price }

    # 최저가 찾기
    lowest_price = valid_bidders.map { |b| b[:bid_price] }.min

    # 가격점수 계산 (최저가 = 만점, 나머지는 비례 배점)
    valid_bidders.map do |bidder|
      price_score = if bidder[:bid_price] == lowest_price
                      price_max
                    else
                      # 가격점수 = 만점 × (최저가 / 해당업체가)
                      price_max * (lowest_price / bidder[:bid_price])
                    end

      bidder.merge(
        price_score: price_score.round(2),
        is_valid: true,
        floor_price: floor_price
      )
    end
  end

  def calculate_total_scores(bidders, price_max, non_price_max)
    bidders.map do |bidder|
      total_score = bidder[:price_score] + bidder[:non_price_score]
      total_max = price_max + non_price_max
      total_score_100 = (total_score / total_max * 100).round(2)

      bidder.merge(
        total_score: total_score.round(2),
        total_score_100: total_score_100,
        is_qualified: total_score_100 >= 95
      )
    end.sort_by { |b| -b[:total_score_100] }
  end
end
