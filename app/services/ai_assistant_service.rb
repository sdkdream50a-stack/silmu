# AI 실무 어시스턴트 서비스
# Claude Haiku를 사용하여 공무원 계약·예산 실무 질문에 답변
class AiAssistantService
  DAILY_LIMIT_GUEST  = 3
  DAILY_LIMIT_USER   = 20

  SYSTEM_PROMPT = <<~PROMPT.freeze
    당신은 대한민국 공무원의 계약·예산·행정 실무를 돕는 전문 AI 어시스턴트입니다.

    답변 원칙:
    1. 관련 법령(국가계약법, 지방계약법, 여비규정 등)을 근거로 정확하게 답변
    2. 실무에서 바로 활용할 수 있도록 구체적으로 설명
    3. 불확실한 경우 반드시 "해당 기관의 법무 담당자나 상급기관에 확인하세요"라고 명시
    4. 한국어로 간결하고 명확하게 답변 (마크다운 사용 가능)
    5. 민감한 개인정보나 특정인 비방 내용은 답변 거부
  PROMPT

  def initialize(user: nil)
    @user = user
    @api_key = ENV["ANTHROPIC_API_KEY"]
  end

  # 일일 사용 한도 초과 여부 확인
  def limit_exceeded?(ip_or_id)
    limit = @user ? DAILY_LIMIT_USER : DAILY_LIMIT_GUEST
    count = current_usage(ip_or_id)
    count >= limit
  end

  def current_usage(ip_or_id)
    Rails.cache.read(usage_key(ip_or_id)).to_i
  end

  def remaining_count(ip_or_id)
    limit = @user ? DAILY_LIMIT_USER : DAILY_LIMIT_GUEST
    [limit - current_usage(ip_or_id), 0].max
  end

  def increment_usage(ip_or_id)
    key = usage_key(ip_or_id)
    Rails.cache.increment(key)
    # 자정까지 만료 설정 (첫 사용 시)
    unless Rails.cache.read("#{key}_ttl_set")
      seconds_until_midnight = Time.current.end_of_day.to_i - Time.current.to_i
      Rails.cache.write("#{key}_ttl_set", true, expires_in: seconds_until_midnight)
      # Solid Cache는 TTL 갱신 미지원이므로 키를 만료시간과 함께 재설정
      current = Rails.cache.read(key).to_i
      Rails.cache.write(key, current, expires_in: seconds_until_midnight.seconds)
    end
  end

  # 비스트리밍 응답 (ActionCable broadcast용)
  def answer(question, topic_context: nil)
    return { error: "API 키가 설정되지 않았습니다." } unless @api_key.present?

    client = Anthropic::Client.new

    messages = build_messages(question, topic_context)

    response = client.messages(
      model: "claude-haiku-4-5-20251001",
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages: messages
    )

    { text: response.content.first.text }
  rescue => e
    Rails.logger.error "[AiAssistantService] 오류: #{e.class} #{e.message}"
    { error: "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요." }
  end

  private

  def build_messages(question, topic_context)
    if topic_context.present?
      [{
        role: "user",
        content: <<~MSG
          [참고 법령 정보]
          #{topic_context.first(2000)}

          [질문]
          #{question}
        MSG
      }]
    else
      [{ role: "user", content: question }]
    end
  end

  def usage_key(ip_or_id)
    date = Time.zone.today.strftime("%Y%m%d")
    prefix = @user ? "ai_assistant_user" : "ai_assistant_ip"
    "#{prefix}/#{ip_or_id}/#{date}"
  end
end
