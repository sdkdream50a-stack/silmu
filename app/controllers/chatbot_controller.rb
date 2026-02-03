class ChatbotController < ApplicationController
  def index
    @boards = CafeArticle.board_list.first(20)
    @total_count = CafeArticle.count
    @recent_popular = CafeArticle.popular.limit(10)
    @topics = Topic.published.popular.limit(10)
  end

  def price_guide
    @category = params[:category].to_s # goods, service, construction
    @price = params[:price].to_i

    if @price > 0 && @category.present?
      @result = calculate_contract_method(@category, @price)
      @topic = Topic.find_by(slug: 'private-contract')
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def search
    @query = params[:q].to_s.strip
    @board = params[:board]

    if @query.present?
      # 1. 토픽 매칭 시도
      @topic = Topic.find_by_query(@query)

      # 2. 관련 게시글 검색
      @results = CafeArticle.find_similar(@query, limit: 20)
      @results = @results.by_board(@board) if @board.present?
    else
      @results = CafeArticle.none
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def calculate_contract_method(category, price)
    case category
    when 'goods', 'service' # 물품, 용역
      if price <= 22_000_000
        {
          method: '1인 견적 수의계약',
          method_type: 'private_1',
          description: '1개 업체에서 견적서를 받아 계약 가능',
          color: 'green',
          checklist: [
            '예정가격 작성',
            '견적서 1부 징구',
            '수의계약 사유서 작성',
            '계약서 작성'
          ],
          tips: [
            '나라장터 등록 없이 가능',
            '견적서는 반드시 계약 전에 징구'
          ]
        }
      elsif price <= 50_000_000
        {
          method: '2인 이상 견적 수의계약',
          method_type: 'private_2',
          description: '2개 이상 업체에서 견적서를 받아 최저가로 계약',
          color: 'blue',
          checklist: [
            '예정가격 작성',
            '2인 이상 견적서 징구 (동일 조건)',
            '최저가 업체 선정',
            '수의계약 사유서 작성',
            '계약서 작성'
          ],
          tips: [
            '동일한 규격/조건으로 견적 요청',
            '견적 마감일시 명시하여 통보'
          ]
        }
      else
        {
          method: '경쟁입찰',
          method_type: 'bidding',
          description: '나라장터를 통한 공개경쟁입찰 진행',
          color: 'purple',
          checklist: [
            '입찰공고 (나라장터)',
            '현장설명회 (필요시)',
            '입찰서 접수',
            '개찰 및 낙찰자 결정',
            '계약 체결'
          ],
          tips: [
            '공고기간 준수 (7일 이상)',
            '2회 유찰 시 수의계약 전환 가능'
          ]
        }
      end
    when 'construction' # 공사
      if price <= 50_000_000
        {
          method: '1인 견적 수의계약',
          method_type: 'private_1',
          description: '1개 업체에서 견적서를 받아 계약 가능',
          color: 'green',
          checklist: [
            '설계서/도면 준비',
            '예정가격 작성',
            '견적서 1부 징구',
            '수의계약 사유서 작성',
            '계약서 작성'
          ],
          tips: [
            '건설업 등록 업체 확인',
            '설계변경 가능성 고려'
          ]
        }
      elsif price <= 200_000_000
        {
          method: '2인 이상 견적 수의계약',
          method_type: 'private_2',
          description: '2개 이상 업체에서 견적서를 받아 최저가로 계약',
          color: 'blue',
          checklist: [
            '설계서/도면 준비',
            '예정가격 작성',
            '2인 이상 견적서 징구',
            '최저가 업체 선정',
            '계약서 작성'
          ],
          tips: [
            '건설업 등록증 확인',
            '시공능력평가액 확인'
          ]
        }
      else
        {
          method: '경쟁입찰',
          method_type: 'bidding',
          description: '나라장터를 통한 공개경쟁입찰 진행',
          color: 'purple',
          checklist: [
            '설계서/도면 확정',
            '입찰공고 (나라장터)',
            '현장설명회',
            '입찰/개찰',
            '적격심사 (추정가 300억 미만)',
            '계약 체결'
          ],
          tips: [
            '공고기간 준수 (7일~40일)',
            '현장설명 필수 여부 확인'
          ]
        }
      end
    else
      nil
    end
  end
end
