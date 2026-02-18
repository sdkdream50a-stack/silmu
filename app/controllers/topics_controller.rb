class TopicsController < ApplicationController
  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @topic.increment_view!
    @related_topics = @topic.related_topics
    @related_articles = CafeArticle.find_similar(@topic.name, limit: 10)
    @related_audit_cases = @topic.related_audit_cases
    @audit_case_total = AuditCase.published.count

    # 부모 토픽인 경우 키워드별 매칭 토픽을 미리 조회 (N+1 방지)
    @keyword_topic_map = @topic.parent_id.nil? ? @topic.keyword_topic_map : {}

    # 키워드 파라미터가 있으면 해당 키워드 섹션 표시
    @active_keyword = params[:keyword]
    @page_rendered_at = Time.current

    # SEO 메타 태그
    set_meta_tags(
      title: "#{@topic.name} — 법령·절차·실무 가이드",
      description: @topic.summary.truncate(155),
      keywords: @topic.keywords,
      canonical: canonical_url,
      og: {
        title: "#{@topic.name} 실무 가이드 | 실무.kr",
        description: @topic.summary.truncate(200),
        url: canonical_url,
        type: "article"
      }
    )
  end
end
