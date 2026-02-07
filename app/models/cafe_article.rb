class CafeArticle < ApplicationRecord
  include PgSearch::Model

  # 전문 검색 설정
  pg_search_scope :search_by_title,
    against: :title,
    using: {
      tsearch: { prefix: true, dictionary: "simple" },
      trigram: { threshold: 0.1 }
    }

  # 게시판별 검색
  scope :by_board, ->(board) { where(board: board) if board.present? }

  # 인기순 정렬
  scope :popular, -> { order(view_count: :desc) }

  # 최신순 정렬
  scope :recent, -> { order(written_at: :desc) }

  # 유사 질문 찾기
  def self.find_similar(query, limit: 10)
    return none if query.blank?

    # 키워드 추출 (2글자 이상 한글/영문)
    keywords = query.scan(/[가-힣a-zA-Z0-9]+/).select { |w| w.length >= 2 }
    return none if keywords.empty?

    # 키워드로 검색
    results = where(
      keywords.map { "title ILIKE ?" }.join(" OR "),
      *keywords.map { |k| "%#{sanitize_sql_like(k)}%" }
    ).order(view_count: :desc).limit(limit)

    results.presence || search_by_title(query).limit(limit)
  end

  # 게시판 목록
  def self.board_list
    group(:board).count(:id).sort_by { |_, count| -count }.to_h
  end
end
