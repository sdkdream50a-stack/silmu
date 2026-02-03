class TopicsController < ApplicationController
  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @topic.increment_view!
    @related_topics = @topic.related_topics
    @related_articles = CafeArticle.find_similar(@topic.name, limit: 10)

    # 키워드 파라미터가 있으면 해당 키워드 섹션 표시
    @active_keyword = params[:keyword]
  end
end
