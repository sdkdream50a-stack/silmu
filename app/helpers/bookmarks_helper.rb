module BookmarksHelper
  # 뷰에서 <%= bookmark_button(@topic) %> 형태로 호출
  # resource: Topic, Guide, AuditCase 인스턴스
  def bookmark_button(resource)
    return "" unless user_signed_in?

    bookmark = current_user.bookmarks.find_by(
      bookmarkable_type: resource.class.name,
      bookmarkable_id: resource.id
    )
    bookmarked = bookmark.present?

    # Turbo 교체 대상 DOM ID
    dom_id = "bookmark_#{resource.class.name}_#{resource.id}"

    content_tag(:div, id: dom_id) do
      render partial: "bookmarks/button",
             locals: { resource: resource, bookmark: bookmark, bookmarked: bookmarked }
    end
  end
end
