class AiAssistantController < ApplicationController
  def index
    @topic = Topic.find_by(slug: params[:topic_slug], published: true)

    set_meta_tags(
      title: "AI 실무 어시스턴트",
      description: "수의계약·입찰·검수·대금지급 등 공무원 계약·예산 실무 질문에 AI가 관련 법령을 근거로 답변해드립니다. 궁금한 실무 사항을 바로 물어보세요."
    )
  end
end
