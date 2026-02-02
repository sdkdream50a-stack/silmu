class TopicsController < ApplicationController
  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @topic.increment_view!
    @related_topics = @topic.related_topics
    @related_articles = CafeArticle.find_similar(@topic.name, limit: 10)
  end
end
