class AiAssistantController < ApplicationController
  def index
    @topic = Topic.find_by(slug: params[:topic_slug], published: true)

    set_meta_tags(
      title: "AI 실무 어시스턴트",
      description: "공무원 계약·예산 실무 질문에 AI가 법령을 근거로 답변해드립니다."
    )
  end
end
