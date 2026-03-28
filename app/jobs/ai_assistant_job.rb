# AI 어시스턴트 응답 생성 Job
# ActionCable을 통해 결과를 broadcast
class AiAssistantJob < ApplicationJob
  queue_as :default

  def perform(session_id:, question:, topic_context: nil, remaining: nil)
    service = AiAssistantService.new

    result = service.answer(question, topic_context: topic_context)

    if result[:error]
      ActionCable.server.broadcast(
        "ai_assistant_#{session_id}",
        { type: "error", message: result[:error] }
      )
    else
      ActionCable.server.broadcast(
        "ai_assistant_#{session_id}",
        { type: "answer", text: result[:text], remaining: remaining }
      )
    end
  end
end
