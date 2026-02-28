class Exam::KeywordsController < ApplicationController
  layout 'exam'

  def index
    @all_keywords = ExamCurriculum.all_keywords.map do |kw|
      detail = ExamKeywordDetails.find(kw[:keyword])
      kw.merge(
        definition: detail&.dig(:definition),
        example: detail&.dig(:example),
        quiz_ids: detail&.dig(:quiz_ids) || []
      )
    end
    @subjects = ExamCurriculum::SUBJECTS
    @detail_count = ExamKeywordDetails.count

    # 과목별 필터
    @filter = params[:subject_id]&.to_i
    @filtered_keywords = if @filter&.positive?
      @all_keywords.select { |k| k[:subject_id] == @filter }
    else
      @all_keywords
    end

    # 가나다 검색
    @search = params[:q].to_s.strip
    if @search.present?
      @filtered_keywords = @filtered_keywords.select do |k|
        k[:keyword].include?(@search) ||
          k[:definition].to_s.include?(@search) ||
          k[:example].to_s.include?(@search)
      end
    end

    @total_count = @all_keywords.size

    set_meta_tags(
      title: "핵심 용어집 — 정의·예시·문제 연결",
      description: "공공조달관리사 표준교재 4권 핵심 용어 #{@total_count}개 완전 정리. 용어 정의, 실무 예시 문장, 관련 모의고사 문제까지 한 번에 확인하세요.",
      keywords: "공공조달 용어, 공공조달관리사 키워드, 공공조달 용어집, VFM, 낙찰하한율, 수의계약, 나라장터",
      canonical: "https://exam.silmu.kr/keywords"
    )
  end
end
