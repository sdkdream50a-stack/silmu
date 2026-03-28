# AI 실무 어시스턴트 ActionCable 채널
# 질문 수신 → Claude API 호출 → 응답 broadcast
class AiAssistantChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ai_assistant_#{params[:session_id]}"
  end

  def unsubscribed
  end

  def ask(data)
    question = data["question"].to_s.strip.truncate(500)
    return unless question.present?

    session_id   = params[:session_id]
    topic_slug   = data["topic_slug"].presence
    ip_or_id     = current_user&.id&.to_s || session_id

    service = AiAssistantService.new(user: current_user)

    if service.limit_exceeded?(ip_or_id)
      limit = current_user ? AiAssistantService::DAILY_LIMIT_USER : AiAssistantService::DAILY_LIMIT_GUEST
      ActionCable.server.broadcast(
        "ai_assistant_#{session_id}",
        { type: "error", message: "오늘 사용 한도(#{limit}회)에 도달했습니다. 내일 다시 이용해주세요." }
      )
      return
    end

    # 토픽 컨텍스트 구성
    topic_context = nil
    if topic_slug.present?
      topic = Topic.find_by(slug: topic_slug, published: true)
      if topic
        topic_context = [
          topic.law_content,
          topic.decree_content,
          topic.rule_content,
          topic.commentary,
          topic.practical_tips
        ].compact.join("\n\n")
      end
    end

    # 사용량 증가
    service.increment_usage(ip_or_id)

    # Claude API 호출 (백그라운드)
    AiAssistantJob.perform_later(
      session_id: session_id,
      question: question,
      topic_context: topic_context,
      remaining: service.remaining_count(ip_or_id)
    )
  end
end
