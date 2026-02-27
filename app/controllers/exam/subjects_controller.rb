class Exam::SubjectsController < ApplicationController
  layout 'exam'

  def index
    @subjects = ExamCurriculum::SUBJECTS

    set_meta_tags(
      title: "4권 커리큘럼",
      description: "공공조달관리사 표준교재 4권(27장) 기반 체계적 학습 커리큘럼. 1권 공공조달의 이해, 2권 계획분석, 3권 계약관리, 4권 관리실무.",
      keywords: "공공조달관리사 커리큘럼, 공공조달관리사 교재, 공공조달관리사 공부",
      canonical: "https://exam.silmu.kr/subjects"
    )
  end

  def show
    @subject = ExamCurriculum.find_subject(params[:id])
    return redirect_to exam_subjects_path, alert: "과목을 찾을 수 없습니다." unless @subject

    @colors = ExamCurriculum.colors(@subject[:color])
    @prev_subject = ExamCurriculum.find_subject(@subject[:id] - 1)
    @next_subject = ExamCurriculum.find_subject(@subject[:id] + 1)

    set_meta_tags(
      title: "#{@subject[:number]}: #{@subject[:title]}",
      description: "공공조달관리사 #{@subject[:number]} #{@subject[:title]}(#{@subject[:subtitle]}) — #{@subject[:total_chapters]}개 챕터 학습목표·핵심키워드·시험 포인트 정리.",
      keywords: "공공조달관리사 #{@subject[:title]}, #{@subject[:chapters].map { |c| c[:title] }.join(', ')}",
      canonical: "https://exam.silmu.kr/subjects/#{@subject[:id]}"
    )
  end
end
