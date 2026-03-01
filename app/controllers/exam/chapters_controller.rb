class Exam::ChaptersController < ApplicationController
  layout 'exam'

  def show
    @subject = ExamCurriculum.find_subject(params[:subject_id])
    return redirect_to exam_subjects_path, alert: "과목을 찾을 수 없습니다." unless @subject

    @chapter = ExamCurriculum.find_chapter(params[:subject_id], params[:number])
    return redirect_to exam_subject_path(@subject[:id]), alert: "챕터를 찾을 수 없습니다." unless @chapter

    @colors = ExamCurriculum.colors(@subject[:color])

    # 정적 콘텐츠이므로 HTTP 캐싱
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    # 이전/다음 챕터
    chapters = @subject[:chapters]
    current_index = chapters.index { |c| c[:number] == @chapter[:number] }
    @prev_chapter = chapters[current_index - 1] if current_index > 0
    @next_chapter = chapters[current_index + 1] if current_index < chapters.length - 1

    set_meta_tags(
      title: "#{@subject[:number]} 제#{@chapter[:number]}장: #{@chapter[:title]}",
      description: "공공조달관리사 #{@subject[:number]} #{@subject[:title]} — 제#{@chapter[:number]}장 #{@chapter[:title]}. 학습목표·핵심키워드·시험 출제 포인트 완벽 정리.",
      keywords: "공공조달관리사 #{@chapter[:title]}, #{@chapter[:keywords].first(4).join(', ')}",
      canonical: "https://exam.silmu.kr/subjects/#{@subject[:id]}/chapters/#{@chapter[:number]}"
    )
  end
end
