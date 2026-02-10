class TopicsController < ApplicationController
  def show
    # 캐시 방지
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    @topic = Topic.find_by!(slug: params[:slug])
    @topic.increment_view!
    @related_topics = @topic.related_topics
    @related_articles = CafeArticle.find_similar(@topic.name, limit: 10)

    # 키워드 파라미터가 있으면 해당 키워드 섹션 표시
    @active_keyword = params[:keyword]
    @page_rendered_at = Time.current

    # SEO 메타 태그
    set_meta_tags(
      title: "#{@topic.name} — 법령·절차·실무 가이드",
      description: @topic.summary.truncate(155),
      keywords: @topic.keywords,
      og: {
        title: "#{@topic.name} 실무 가이드 | 실무.kr",
        description: @topic.summary.truncate(200),
        url: request.original_url,
        type: "article"
      }
    )
  end
end
