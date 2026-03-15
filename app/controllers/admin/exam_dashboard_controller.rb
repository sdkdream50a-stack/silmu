class Admin::ExamDashboardController < Admin::BaseController
  def index
    # 신고 1회 이상 댓글 (신고 많은 순)
    @reported_comments = ExamQuestionComment
      .where("reported_count >= 1")
      .order(reported_count: :desc, created_at: :desc)
      .limit(50)

    # 문제 오류 제보 (최신순)
    @question_reports = ExamQuestionReport
      .order(created_at: :desc)
      .limit(50)

    # 요약 통계
    @stats = {
      total_comments: ExamQuestionComment.count,
      hidden_comments: ExamQuestionComment.where(hidden: true).count,
      reported_comments: ExamQuestionComment.where("reported_count >= 1").count,
      total_reports: ExamQuestionReport.count
    }
  end

  def restore_comment
    comment = ExamQuestionComment.find(params[:id])
    comment.update!(hidden: false, reported_count: 0)
    redirect_to admin_exam_dashboard_index_path, notice: "댓글이 복구되었습니다."
  end

  def delete_comment
    comment = ExamQuestionComment.find(params[:id])
    comment.destroy!
    redirect_to admin_exam_dashboard_index_path, notice: "댓글이 삭제되었습니다."
  end

  def delete_report
    report = ExamQuestionReport.find(params[:id])
    report.destroy!
    redirect_to admin_exam_dashboard_index_path, notice: "제보가 삭제되었습니다."
  end
end
