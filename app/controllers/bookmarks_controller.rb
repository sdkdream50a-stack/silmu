class BookmarksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bookmark, only: [:destroy]

  # GET /bookmarks — 마이페이지 북마크 목록
  def index
    @bookmarks = current_user.bookmarks.recent.includes(:bookmarkable)
    @topics      = @bookmarks.topics.map(&:bookmarkable).compact
    @guides      = @bookmarks.guides.map(&:bookmarkable).compact
    @audit_cases = @bookmarks.audit_cases.map(&:bookmarkable).compact
  end

  # POST /bookmarks
  def create
    type = bookmark_params[:bookmarkable_type]
    id   = bookmark_params[:bookmarkable_id]

    unless Bookmark::ALLOWED_TYPES.include?(type)
      return respond_with_error("지원하지 않는 북마크 유형입니다", :unprocessable_entity)
    end

    bookmarkable = type.constantize.find_by(id: id)
    unless bookmarkable
      return respond_with_error("해당 항목을 찾을 수 없습니다", :not_found)
    end

    @bookmark = current_user.bookmarks.find_or_initialize_by(
      bookmarkable_type: type,
      bookmarkable_id: id
    )

    if @bookmark.persisted?
      return respond_with_error("이미 북마크된 항목입니다", :unprocessable_entity)
    end

    if @bookmark.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            bookmark_dom_id(bookmarkable),
            partial: "bookmarks/button",
            locals: { resource: bookmarkable, bookmark: @bookmark, bookmarked: true }
          )
        end
        format.json { render json: { success: true, bookmark_id: @bookmark.id }, status: :created }
        format.html { redirect_back fallback_location: root_path, notice: "북마크에 추가되었습니다." }
      end
    else
      respond_with_error(@bookmark.errors.full_messages.first, :unprocessable_entity)
    end
  end

  # DELETE /bookmarks/:id
  def destroy
    bookmarkable = @bookmark.bookmarkable

    @bookmark.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          bookmark_dom_id(bookmarkable),
          partial: "bookmarks/button",
          locals: { resource: bookmarkable, bookmark: nil, bookmarked: false }
        )
      end
      format.json { render json: { success: true }, status: :ok }
      format.html { redirect_back fallback_location: bookmarks_path, notice: "북마크가 해제되었습니다." }
    end
  end

  private

  def set_bookmark
    @bookmark = current_user.bookmarks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error("북마크를 찾을 수 없습니다", :not_found)
  end

  def bookmark_params
    params.require(:bookmark).permit(:bookmarkable_type, :bookmarkable_id)
  end

  def respond_with_error(message, status)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { message: message }), status: status }
      format.json { render json: { success: false, error: message }, status: status }
      format.html { redirect_back fallback_location: root_path, alert: message }
    end
  end

  # DOM ID: "bookmark_Topic_123" 형식
  def bookmark_dom_id(resource)
    "bookmark_#{resource.class.name}_#{resource.id}"
  end
  helper_method :bookmark_dom_id
end
