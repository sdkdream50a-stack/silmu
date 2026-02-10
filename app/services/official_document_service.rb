class OfficialDocumentService
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  DOC_TYPES = {
    "draft" => "기안문(품의서)",
    "cooperation" => "협조문",
    "notification" => "통보문",
    "report" => "보고문",
    "reply" => "회신문",
    "inquiry" => "의견조회문"
  }.freeze

  TONE_LABELS = {
    "normal" => "일반",
    "formal" => "격식",
    "concise" => "간결"
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT
    당신은 대한민국 공무원 공문서 작성 전문가입니다.
    행정업무의 운영 및 혁신에 관한 규정(대통령령)에 따라 공문서를 작성합니다.

    [공문서 작성 원칙]
    1. 항목 번호 체계: 1. → 가. → 1) → 가) → (1) → (가)
    2. 문체: "~합니다/됩니다" 또는 "~하오니 ~하여 주시기 바랍니다"
    3. 날짜: 2026. 2. 10. 형식 (연.월.일.)
    4. 간결·명확하게 작성, 불필요한 수식어 배제
    5. 법령 인용 시: 「지방계약법 시행령」 제25조제1항 형식 (법령명은 「」로 감싸기)
    6. 수신자 다음에 반드시 (경유) 줄을 포함
    7. 붙임 목록의 마지막 항목 끝에 "끝." 표기

    [문서 유형별 본문 구조]
    - 기안문(품의서): 1.추진배경/사유 → 2.세부내용(예산·일정 등) → 3.이행계획 → 4.붙임
    - 협조문: 1.관련(근거 문서) → 2.협조요청 사유 → 3.요청사항 → 4.회신기한 → 5.붙임
    - 통보문: 1.관련(근거 문서) → 2.통보내용 → 3.이행사항/유의사항 → 4.붙임
    - 보고문: 1.개요 → 2.추진현황/실적 → 3.문제점 및 개선방안 → 4.향후계획 → 5.붙임
    - 회신문: 1.관련(원 질의 문서번호) → 2.회신내용 → 3.붙임
    - 의견조회문: 1.관련(근거) → 2.조회사항/배경 → 3.의견요청 항목 → 4.회신기한 및 방법 → 5.붙임

    [계약업무 관련 참조]
    - 수의계약: 「지방계약법 시행령」 제25조
    - 계약보증금: 「지방계약법 시행령」 제51조
    - 검수/검사: 「지방계약법 시행령」 제65조
    - 대금지급: 「지방계약법 시행령」 제68조

    [출력 형식]
    반드시 아래 HTML 구조로만 응답하세요. 마크다운이나 설명 텍스트는 포함하지 마세요.
    각 요소의 style 속성을 반드시 포함하세요.

    <div style="font-family:'맑은 고딕',sans-serif;max-width:700px;margin:0 auto;padding:40px 50px;background:#fff;line-height:1.8;font-size:15px;color:#1e293b">
      <div style="text-align:center;margin-bottom:32px">
        <div style="font-size:13px;color:#64748b;margin-bottom:4px">[기관명]</div>
      </div>
      <div style="margin-bottom:6px"><span style="font-weight:700">수신:</span> 수신자 (담당부서)</div>
      <div style="margin-bottom:6px;color:#94a3b8">(경유)</div>
      <div style="margin-bottom:24px"><span style="font-weight:700">제목:</span> <span style="font-weight:700">제목 내용</span></div>
      <div style="margin-bottom:24px;white-space:pre-wrap">
        본문 내용을 여기에 작성합니다.
        항목 번호 체계(1. → 가. → 1))를 준수합니다.
      </div>
      <div style="margin-top:32px;color:#64748b;font-size:14px">
        붙임  1. 첨부파일명 1부.<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. 첨부파일명 1부.  끝.
      </div>
      <div style="text-align:right;margin-top:40px;font-weight:700">○○과장  [성명]</div>
      <div style="margin-top:24px;padding-top:16px;border-top:1px solid #e2e8f0;font-size:13px;color:#64748b">
        담당자: 성명 (☎ 연락처)<br>
        결재: 담당 → 과장
      </div>
    </div>
  PROMPT

  def initialize(params)
    @api_key = ENV["ANTHROPIC_API_KEY"]
    @doc_type = params[:doc_type]
    @recipient = params[:recipient]
    @title = params[:title]
    @content_summary = params[:content_summary]
    @sender_dept = params[:sender_dept]
    @sender_name = params[:sender_name]
    @sender_phone = params[:sender_phone]
    @attachments = params[:attachments]
    @related_doc = params[:related_doc]
    @tone = params[:tone] || "normal"
  end

  def generate
    return nil unless @api_key

    content = call_anthropic_api
    sanitize_html(content) if content
  rescue => e
    Rails.logger.error "OfficialDocumentService error: #{e.message}"
    nil
  end

  private

  def build_user_message
    type_label = DOC_TYPES[@doc_type] || @doc_type
    tone_label = TONE_LABELS[@tone] || "일반"
    today = Date.today.strftime("%Y. %-m. %-d.")

    msg = "다음 정보로 #{type_label}을(를) 작성해주세요.\n\n"
    msg += "- 문서 유형: #{type_label}\n"
    msg += "- 수신: #{@recipient}\n"
    msg += "- 제목: #{@title}\n"
    msg += "- 작성일: #{today}\n"
    msg += "- 톤: #{tone_label}\n"
    msg += "- 핵심 내용:\n#{@content_summary}\n"

    msg += "- 발신 부서: #{@sender_dept}\n" if @sender_dept.present?
    msg += "- 담당자: #{@sender_name}\n" if @sender_name.present?
    msg += "- 연락처: #{@sender_phone}\n" if @sender_phone.present?
    msg += "- 관련 문서: #{@related_doc}\n" if @related_doc.present?

    if @attachments.present?
      files = @attachments.split(",").map(&:strip).reject(&:blank?)
      msg += "- 붙임 파일: #{files.join(', ')}\n"
    end

    msg += "\n위 정보를 바탕으로 행정업무운영규정에 맞는 공문서 HTML을 작성하세요."
    msg
  end

  def call_anthropic_api
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
      system: SYSTEM_PROMPT,
      messages: [
        { role: "user", content: build_user_message }
      ]
    }.to_json

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      result.dig("content", 0, "text")
    else
      Rails.logger.error "OfficialDocumentService API error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "OfficialDocumentService API call failed: #{e.message}"
    nil
  end

  def sanitize_html(content)
    return nil if content.blank?

    if content.include?("```")
      match = content.match(/```(?:html)?\s*([\s\S]*?)```/)
      content = match[1] if match
    end

    content.strip
  end
end
