# frozen_string_literal: true

# P1.55 §24·§25 — 법령 변경 검토 큐 (최소 Admin UI).
#
# 목표는 아름다운 UI 가 아니라, 한 화면에서 다음을 보는 것:
#   변경된 문서 · 시행일 · diff · 영향 콘텐츠 · 영향 등급 · 검토 상태
#
# 이 컨트롤러는 **게시 콘텐츠를 수정하지 않는다.** AuthorityReviewTask#decide! 만 호출하며,
# 그 안에서 검증 이벤트 기록과 freshness 상태 전이가 일어난다.
class Admin::AuthorityReviewsController < Admin::BaseController
  def index
    @sources = AuthoritySource.order(:key)
    @documents = AuthorityDocument.includes(:current_version, :authority_source).order(:key)

    scope = AuthorityReviewTask.includes(authority_change_event: :authority_document)
    @status = params[:status].presence || "open"
    scope = @status == "all" ? scope : scope.open
    scope = scope.where(impact_class: params[:impact]) if params[:impact].present?

    @tasks = scope.by_priority.limit(200)
    @stats = {
      open: AuthorityReviewTask.open.count,
      total: AuthorityReviewTask.count,
      by_impact: AuthorityReviewTask.open.group(:impact_class).count,
      events_open: AuthorityChangeEvent.open.count,
      verifications_7d: AuthorityVerificationEvent.where(reviewed_at: 7.days.ago..).count,
      link_count: ContentAuthorityLink.count
    }
  end

  # §25 — 기존 state model 과 정확히 일치하는 결정만 허용한다.
  def decide
    task = AuthorityReviewTask.find(params[:id])
    decision = params[:decision].to_s

    unless AuthorityReviewTask::DECISIONS.include?(decision)
      return redirect_to admin_authority_reviews_path, alert: "알 수 없는 결정: #{decision}"
    end

    task.decide!(decision: decision, reviewer: current_user.email, note: params[:note].presence)
    redirect_to admin_authority_reviews_path(status: params[:status]),
                notice: "#{task.affected_label} → #{decision} 처리했습니다."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to admin_authority_reviews_path, alert: "처리 실패: #{e.message}"
  end
end
