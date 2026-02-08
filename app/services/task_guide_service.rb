class TaskGuideService
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  def initialize
    @api_key = ENV["ANTHROPIC_API_KEY"]
  end

  def generate(task_title, category = nil)
    return nil unless @api_key

    guide = TaskGuide.find_or_initialize_by(task_title: task_title)
    return guide if guide.completed?

    guide.update!(category: category, status: :generating)

    content = call_anthropic_api(build_prompt(task_title, category))
    if content
      guide.update!(content: content, status: :completed)
    else
      guide.update!(status: :failed)
    end

    guide
  rescue => e
    Rails.logger.error "TaskGuideService error: #{e.message}"
    guide&.update(status: :failed) if guide&.persisted?
    guide
  end

  private

  def build_prompt(task_title, category)
    cat_label = category.present? ? " (분류: #{category})" : ""
    <<~PROMPT
      당신은 대한민국 지방자치단체 공무원 업무 프로세스 전문가입니다.
      다음 업무의 처리 절차를 단계별로 안내해주세요.

      업무: #{task_title}#{cat_label}

      아래 형식의 HTML로 응답해주세요. 마크다운이 아닌 순수 HTML만 사용하세요.
      <div> 태그와 인라인 스타일을 사용하세요.

      반드시 다음 4개 섹션을 포함하세요:

      1. 업무 개요 (2~3문장으로 업무의 목적과 중요성)
      2. 처리 절차 (5~8단계, 각 단계에 구체적인 실무 행동 포함)
      3. 주의사항 (3~5개, 실무에서 자주 하는 실수나 주의점)
      4. 관련 법령/지침 (해당되는 경우)

      HTML 형식 예시:
      <div style="margin-bottom:16px">
        <h3 style="font-size:15px;font-weight:700;color:#1e293b;margin-bottom:8px">📋 업무 개요</h3>
        <p style="font-size:13px;color:#475569;line-height:1.7">설명...</p>
      </div>
      <div style="margin-bottom:16px">
        <h3 style="font-size:15px;font-weight:700;color:#1e293b;margin-bottom:8px">📌 처리 절차</h3>
        <div style="margin-bottom:10px">
          <div style="display:flex;align-items:flex-start;gap:10px;margin-bottom:8px">
            <span style="flex-shrink:0;width:24px;height:24px;border-radius:50%;background:#6366f1;color:white;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center">1</span>
            <div>
              <p style="font-size:13px;font-weight:600;color:#334155">단계 제목</p>
              <p style="font-size:12px;color:#64748b;margin-top:2px">구체적 설명...</p>
            </div>
          </div>
        </div>
      </div>
      <div style="margin-bottom:16px">
        <h3 style="font-size:15px;font-weight:700;color:#1e293b;margin-bottom:8px">⚠️ 주의사항</h3>
        <ul style="list-style:none;padding:0;margin:0">
          <li style="font-size:13px;color:#475569;padding:6px 0;border-bottom:1px dashed #e2e8f0">• 주의사항 내용</li>
        </ul>
      </div>
      <div>
        <h3 style="font-size:15px;font-weight:700;color:#1e293b;margin-bottom:8px">📖 관련 법령</h3>
        <p style="font-size:12px;color:#64748b;line-height:1.7">관련 법령 정보...</p>
      </div>

      HTML만 출력하세요. 다른 설명이나 마크다운은 포함하지 마세요.
    PROMPT
  end

  def call_anthropic_api(prompt)
    return nil unless @api_key

    uri = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = @api_key
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: "claude-haiku-4-5-20251001",
      max_tokens: 2000,
      messages: [
        { role: "user", content: prompt }
      ]
    }.to_json

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      content = result.dig("content", 0, "text")
      sanitize_html(content)
    else
      Rails.logger.error "TaskGuideService API error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "TaskGuideService API call failed: #{e.message}"
    nil
  end

  def sanitize_html(content)
    return nil if content.blank?

    # HTML 블록만 추출 (```html ... ``` 감싸진 경우 처리)
    if content.include?("```")
      match = content.match(/```(?:html)?\s*([\s\S]*?)```/)
      content = match[1] if match
    end

    content.strip
  end
end
