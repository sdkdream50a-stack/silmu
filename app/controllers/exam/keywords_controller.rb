class Exam::KeywordsController < ApplicationController
  layout 'exam'

  def index
    @all_keywords = ExamCurriculum.all_keywords
    @subjects = ExamCurriculum::SUBJECTS

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
        k[:keyword].include?(@search)
      end
    end

    @total_count = @all_keywords.size

    set_meta_tags(
      title: "핵심 용어집",
      description: "공공조달관리사 표준교재 4권 핵심 용어 #{@total_count}개 완전 정리. 과목별 필터·검색 지원.",
      keywords: "공공조달 용어, 공공조달관리사 키워드, 공공조달 용어집",
      canonical: "https://exam.silmu.kr/keywords"
    )
  end
end
