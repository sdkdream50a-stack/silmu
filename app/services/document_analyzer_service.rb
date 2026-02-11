# frozen_string_literal: true

# AI 문서 분석 서비스
# 견적서, 제안서 등 기존 문서를 분석하여 계약문서 폼 필드 데이터를 추출
class DocumentAnalyzerService
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/jpeg
    image/png
  ].freeze

  MAX_FILE_SIZE = 20.megabytes

  # 프롬프트 변경 시 버전을 올려 캐시 무효화
  PROMPT_VERSION = 3

  EXTRACT_FIELDS = %w[
    project_name organization department budget contract_period
    purpose scope tasks deliverables personnel
    start_date end_date inspection payment remarks
  ].freeze

  # 단순 추출 작업은 Haiku, 복잡한 분석은 Sonnet
  HAIKU_TYPES = %w[task_extraction quote_extraction].freeze

  def initialize
    @api_key = ENV["ANTHROPIC_API_KEY"]
  end

  # 메인 진입점
  def analyze(file:, document_type:)
    return { success: false, error: "API 키가 설정되지 않았습니다." } unless @api_key.present?

    content_type = file.content_type
    unless ALLOWED_CONTENT_TYPES.include?(content_type)
      return { success: false, error: "지원하지 않는 파일 형식입니다. (PDF, JPG, PNG만 가능)" }
    end

    if file.size > MAX_FILE_SIZE
      return { success: false, error: "파일 크기는 20MB 이하여야 합니다." }
    end

    # 파일 해시 기반 캐싱 — 동일 파일 재분석 방지
    file_data = file.read
    file.rewind
    cache_key = "doc_analysis:v#{PROMPT_VERSION}:#{document_type}:#{Digest::SHA256.hexdigest(file_data)}"
    cached = Rails.cache.read(cache_key)
    return cached if cached

    result = if content_type == "application/pdf"
      analyze_pdf(file, document_type)
    else
      analyze_image(file, document_type, content_type)
    end

    # 성공한 결과만 캐싱 (24시간)
    Rails.cache.write(cache_key, result, expires_in: 24.hours) if result[:success]

    result
  rescue => e
    Rails.logger.error("DocumentAnalyzerService error: #{e.message}")
    { success: false, error: "문서 분석 중 오류가 발생했습니다." }
  end

  # 다중 파일 분석 (견적서 여러 장 등)
  def analyze_multiple(files:, document_type:)
    return { success: false, error: "API 키가 설정되지 않았습니다." } unless @api_key.present?
    return { success: false, error: "파일을 업로드해주세요." } if files.blank?

    # 단일 파일이면 기존 메서드로 위임
    return analyze(file: files.first, document_type: document_type) if files.size == 1

    files.each do |file|
      unless file.respond_to?(:content_type) && ALLOWED_CONTENT_TYPES.include?(file.content_type)
        return { success: false, error: "지원하지 않는 파일 형식입니다. (PDF, JPG, PNG만 가능)" }
      end
      if file.size > MAX_FILE_SIZE
        return { success: false, error: "개별 파일 크기는 20MB 이하여야 합니다." }
      end
    end

    # 다중 파일 캐시 키
    digests = files.map { |f| d = f.read; f.rewind; Digest::SHA256.hexdigest(d) }
    cache_key = "doc_analysis:v#{PROMPT_VERSION}:#{document_type}:multi:#{Digest::SHA256.hexdigest(digests.sort.join)}"
    cached = Rails.cache.read(cache_key)
    return cached if cached

    @current_document_type = document_type

    pdf_files = files.select { |f| f.content_type == "application/pdf" }
    image_files = files.reject { |f| f.content_type == "application/pdf" }

    content_blocks = []

    # 이미지 블록 추가
    image_files.each do |file|
      base64_data = Base64.strict_encode64(file.read)
      file.rewind
      content_blocks << {
        type: "image",
        source: { type: "base64", media_type: file.content_type, data: base64_data }
      }
    end

    # PDF 텍스트 추출·결합
    pdf_text = pdf_files.map { |f| extract_pdf_text(f) }.reject(&:blank?).join("\n\n---\n\n")
    if pdf_text.present?
      max_len = [8000 * pdf_files.size, 24000].min
      pdf_text = pdf_text[0..max_len] if pdf_text.length > max_len
    end

    prompt = build_prompt(document_type, pdf_text.presence)
    content_blocks << { type: "text", text: prompt }

    messages = [{ role: "user", content: content_blocks }]
    result = call_api(messages)

    Rails.cache.write(cache_key, result, expires_in: 24.hours) if result[:success]
    result
  rescue => e
    Rails.logger.error("DocumentAnalyzerService multi-file error: #{e.message}")
    { success: false, error: "문서 분석 중 오류가 발생했습니다." }
  end

  private

  def model_for_type(document_type)
    HAIKU_TYPES.include?(document_type) ? "claude-haiku-4-5-20251001" : "claude-sonnet-4-20250514"
  end

  def analyze_pdf(file, document_type)
    @current_document_type = document_type
    text = extract_pdf_text(file)

    if text.blank?
      return {
        success: false,
        error: "PDF에서 텍스트를 추출할 수 없습니다. 스캔 문서인 경우 JPG/PNG 이미지로 변환 후 업로드해주세요."
      }
    end

    # 텍스트가 너무 길면 잘라냄
    text = text[0..8000] if text.length > 8000

    prompt = build_prompt(document_type, text)
    messages = [{ role: "user", content: prompt }]

    call_api(messages)
  end

  def analyze_image(file, document_type, content_type)
    @current_document_type = document_type
    base64_data = Base64.strict_encode64(file.read)
    file.rewind

    media_type = content_type == "image/jpeg" ? "image/jpeg" : "image/png"

    prompt = build_prompt(document_type)
    messages = [{
      role: "user",
      content: [
        {
          type: "image",
          source: {
            type: "base64",
            media_type: media_type,
            data: base64_data
          }
        },
        {
          type: "text",
          text: prompt
        }
      ]
    }]

    call_api(messages)
  end

  def extract_pdf_text(file)
    reader = PDF::Reader.new(file.tempfile)
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.error("PDF text extraction error: #{e.message}")
    ""
  end

  def build_prompt(document_type, extracted_text = nil)
    # 전용 프롬프트
    if document_type == "cost_estimate"
      return build_cost_estimate_prompt(extracted_text)
    end
    if document_type == "progress_inspection"
      return build_progress_inspection_prompt(extracted_text)
    end
    if document_type == "design_change"
      return build_design_change_prompt(extracted_text)
    end
    if document_type == "cost_calculation"
      return build_cost_calculation_prompt(extracted_text)
    end
    if document_type == "task_extraction"
      return build_task_extraction_prompt(extracted_text)
    end
    if document_type == "quote_extraction"
      return build_quote_extraction_prompt(extracted_text)
    end

    type_label = case document_type
    when "goods" then "구매규격서 (물품 구매)"
    when "service" then "과업내용서 (용역)"
    else "계약문서"
    end

    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 견적서, 제안서, 또는 관련 계약 문서입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 계약 문서 분석 전문가입니다.

      아래 문서에서 #{type_label} 작성에 필요한 정보를 추출해주세요.

      #{text_section}

      ## 추출할 필드
      - project_name: 공사명/구매건명/과업명
      - organization: 발주기관
      - department: 담당부서
      - budget: 추정금액 (숫자만, 원 단위. 예: 50000000)
      - contract_period: 계약기간 (텍스트)
      - purpose: 목적/배경
      - scope: 범위
      - tasks: 세부내용 (배열, 문자열 배열)
      - deliverables: 납품물/산출물 (배열, 문자열 배열)
      - personnel: 인력요건
      - start_date: 착수일
      - end_date: 완료일/납품일
      - inspection: 검수방법
      - payment: 대금지급조건
      - remarks: 특기사항

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. budget은 반드시 숫자만 (원 단위). 예: "5천만원" → 50000000
      4. tasks와 deliverables는 문자열 배열입니다.
      5. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "project_name": "...",
        "organization": "...",
        "department": "...",
        "budget": 50000000,
        "contract_period": "...",
        "purpose": "...",
        "scope": "...",
        "tasks": ["...", "..."],
        "deliverables": ["...", "..."],
        "personnel": "...",
        "start_date": "...",
        "end_date": "...",
        "inspection": "...",
        "payment": "...",
        "remarks": "..."
      }
      ```
    PROMPT
  end

  def build_cost_estimate_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 견적서, 내역서, 또는 공사 관련 문서입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 소액공사 견적서·내역서 분석 전문가입니다.

      아래 문서에서 공사 내역서 작성에 필요한 정보를 추출해주세요.
      견적서, 거래명세서, 내역서 등에서 공종별 항목과 단가를 정확히 추출하는 것이 핵심입니다.

      #{text_section}

      ## 추출할 필드

      ### 기본 정보
      - project_name: 공사명
      - location: 공사 장소
      - duration: 공사 기간 (텍스트)
      - department: 담당 부서
      - manager: 담당자

      ### 내역 항목 (items 배열)
      각 항목에 대해:
      - name: 공종/품명 (예: "방수층 철거", "우레탄 방수")
      - spec: 규격/사양 (예: "우레탄 도막방수 2mm", "시멘트 모르타르")
      - unit: 단위 (예: "m²", "m", "개", "식")
      - qty: 수량 (숫자)
      - unit_price: 단가 (숫자, 원 단위)

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. 금액은 반드시 숫자만 (원 단위). 쉼표 제거.
      4. 부가세, 간접비, 합계 행은 items에 포함하지 마세요. 직접공사비 항목만 추출하세요.
      5. 수량과 단가를 알 수 없으면 qty: 0, unit_price: 0으로 표기하세요.
      6. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "project_name": "...",
        "location": "...",
        "duration": "...",
        "department": "...",
        "manager": "...",
        "items": [
          { "name": "...", "spec": "...", "unit": "m²", "qty": 10, "unit_price": 50000 },
          { "name": "...", "spec": "...", "unit": "식", "qty": 1, "unit_price": 200000 }
        ]
      }
      ```
    PROMPT
  end

  def build_progress_inspection_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 공사계약서, 내역서, 기성신청서 등 공사 관련 문서입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 공사계약 기성검사 전문가입니다.

      아래 문서에서 기성검사 체크리스트 작성에 필요한 정보를 추출해주세요.
      계약서, 물량내역서, 기성신청서, 시방서 등 공사 관련 서류에서 계약정보와 검사정보를 정확히 추출하는 것이 핵심입니다.

      #{text_section}

      ## 추출할 필드

      ### 계약 정보
      - contract_name: 계약명/공사명
      - contract_amount: 계약금액 (숫자, 원 단위. 쉼표 없이)
      - contractor: 시공자/업체명
      - contract_date: 계약일 (YYYY-MM-DD 형식)
      - completion_date: 준공예정일 (YYYY-MM-DD 형식)

      ### 검사 정보
      - round: 검사 차수 (예: "1차", "2차", "준공")
      - inspection_period: 검사 기간 (텍스트)
      - inspection_amount: 금회 기성금액 (숫자, 원 단위)
      - paid_amount: 기지급액 (숫자, 원 단위)

      ### 공사유형 추정
      - inspection_type: 다음 중 하나로 추정 (문서 내용 기반)
        - general_building (건축·토목)
        - small_repair (시설물 보수·수선)
        - electrical (전기·조명·통신)
        - plumbing (급배수·냉난방)
        - painting (도장)
        - waterproof (방수)
        - landscape (조경)

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. 금액은 반드시 숫자만 (원 단위, 쉼표 제거).
      4. 날짜는 YYYY-MM-DD 형식으로 변환하세요.
      5. inspection_type은 공사 내용을 보고 가장 적절한 유형을 선택하세요. 확실하지 않으면 null.
      6. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "contract_name": "...",
        "contract_amount": 50000000,
        "contractor": "...",
        "contract_date": "2026-01-15",
        "completion_date": "2026-03-15",
        "round": "1차",
        "inspection_period": "2026.2.1 ~ 2026.2.15",
        "inspection_amount": 20000000,
        "paid_amount": 0,
        "inspection_type": "small_repair"
      }
      ```
    PROMPT
  end

  def build_design_change_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 설계변경 사유서, 설계도면, 내역서, 현장 확인서 등 공사 설계변경 관련 문서입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 공사계약 설계변경 전문가입니다.

      아래 문서에서 설계변경 검토서 작성에 필요한 정보를 추출해주세요.
      설계변경 사유서, 당초/변경 설계도서, 내역 대비표, 현장 확인서 등에서 핵심 정보를 정확히 추출하세요.

      #{text_section}

      ## 추출할 필드

      ### 변경 내용
      - original_design: 당초 설계 내용 (기존 설계의 구체적 내용)
      - changed_design: 변경 설계 내용 (변경 후 설계의 구체적 내용)
      - detail_reason: 상세 변경 사유 (왜 변경이 필요한지 구체적 이유)

      ### 영향 분석
      - cost_impact: 비용 영향 ("increase" / "decrease" / "same" 중 하나)
      - change_amount: 변경 금액 (숫자, 원 단위. 증액 또는 감액 금액)
      - schedule_change: 공기 변경 여부 (true / false)
      - schedule_days: 변경 일수 (숫자, 일 단위)

      ### 변경사유 유형 추정
      - change_reason: 다음 중 하나로 추정 (문서 내용 기반)
        - site_condition (현장여건 상이: 현장이 설계도서와 다른 경우)
        - design_error (설계서 오류·누락)
        - civil_request (민원 요청)
        - quantity_change (물량 변경)
        - method_change (공법 변경)
        - other (기타)

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. 금액은 반드시 숫자만 (원 단위, 쉼표 제거).
      4. original_design과 changed_design은 구체적인 내용을 그대로 옮기세요.
      5. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "original_design": "옥상 우레탄 도막방수 (2mm)",
        "changed_design": "옥상 시트방수 + 우레탄 도막방수 (이중방수)",
        "detail_reason": "기존 방수층 철거 시 하부 콘크리트 균열이 심하여...",
        "cost_impact": "increase",
        "change_amount": 5000000,
        "schedule_change": true,
        "schedule_days": 7,
        "change_reason": "site_condition"
      }
      ```
    PROMPT
  end

  def build_cost_calculation_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 원가계산서, 용역 견적서, 인건비 산출내역 등 용역 원가 관련 문서입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 용역 원가계산서 분석 전문가입니다.

      아래 문서에서 원가계산서 검토에 필요한 정보를 추출해주세요.
      원가계산서, 견적서, 대가산출내역 등에서 각 비용항목 금액을 정확히 추출하는 것이 핵심입니다.

      #{text_section}

      ## 추출할 필드

      ### 용역 유형 추정
      - service_type: 다음 중 하나로 추정 (문서 내용 기반)
        - general (일반용역: 일반 업무 용역·위탁)
        - research (학술연구용역: 학술·정책·조사 연구 — 기술료 적용)
        - software (SW개발 용역: 소프트웨어 개발·유지보수)
        - design (설계용역: 건축·토목 설계)
        - supervision (감리용역: 건설 감리·시공관리)

      ### 원가 항목 (숫자, 원 단위)
      - direct_labor: 직접인건비 (노임단가 × 투입인월)
      - overhead: 제경비 (간접노무비+기타경비 또는 간접경비)
      - direct_expense: 직접경비 (여비, 인쇄비, 소모품 등 실비)
      - general_admin: 일반관리비
      - profit_or_tech: 이윤 또는 기술료 (학술연구는 기술료)
      - vat: 부가가치세

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. 금액은 반드시 숫자만 (원 단위, 쉼표 제거).
      4. "합계", "총계", "계" 등의 합산 행은 추출하지 마세요. 개별 항목만 추출.
      5. "간접노무비"와 "기타경비"가 별도로 있으면 합산하여 overhead에 넣으세요.
      6. service_type은 문서 제목, 용역명, 대가기준 등을 보고 판단. 확실하지 않으면 null.
      7. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "service_type": "general",
        "direct_labor": 30000000,
        "overhead": 33000000,
        "direct_expense": 3000000,
        "general_admin": 3960000,
        "profit_or_tech": 6696000,
        "vat": 7665600
      }
      ```
    PROMPT
  end

  def call_api(messages)
    uri = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 90

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = @api_key
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: model_for_type(@current_document_type),
      max_tokens: 3000,
      messages: messages
    }.to_json

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      content = result.dig("content", 0, "text")
      parse_response(content)
    else
      Rails.logger.error("Anthropic API error: #{response.code} - #{response.body}")
      { success: false, error: "AI 분석 중 오류가 발생했습니다. (#{response.code})" }
    end
  rescue Net::ReadTimeout
    { success: false, error: "AI 분석 시간이 초과되었습니다. 다시 시도해주세요." }
  rescue => e
    Rails.logger.error("Anthropic API call error: #{e.message}")
    { success: false, error: "AI 서비스 연결에 실패했습니다." }
  end

  def parse_response(content)
    return { success: false, error: "AI 응답이 비어있습니다." } if content.blank?

    # JSON 블록 추출
    json_match = content.match(/\{[\s\S]*\}/)
    return { success: false, error: "AI 응답을 파싱할 수 없습니다." } unless json_match

    fields = JSON.parse(json_match[0])

    # null 값 제거, 빈 배열 제거
    fields = fields.each_with_object({}) do |(key, value), hash|
      next if value.nil?
      next if value.is_a?(Array) && value.empty?
      next if value.is_a?(String) && value.blank?
      hash[key] = value
    end

    # 금액 필드를 정수로 정규화 (AI가 "1,500,000" 같은 문자열로 반환하는 경우 대비)
    %w[supply_amount vat_amount total_amount].each do |key|
      next unless fields.key?(key)
      fields[key] = fields[key].to_s.gsub(/[^\d]/, "").to_i
    end

    # items 배열 내 숫자 필드도 정규화
    if fields["items"].is_a?(Array)
      fields["items"].each do |item|
        %w[qty unit_price].each do |key|
          next unless item.key?(key)
          item[key] = item[key].to_s.gsub(/[^\d]/, "").to_i
        end
      end
    end

    { success: true, fields: fields }
  rescue JSON::ParserError
    { success: false, error: "AI 응답 형식이 올바르지 않습니다." }
  end

  def build_quote_extraction_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 견적서(quotation)입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 수의계약 견적서 분석 전문가입니다.

      아래 견적서에서 사업계획서·소요예산·예정가격 조서 작성에 필요한 정보를 추출해주세요.

      #{text_section}

      ## 추출할 필드

      ### 업체 정보
      - company_name: 업체명 (상호)
      - business_no: 사업자등록번호
      - representative: 대표자명
      - contact_person: 담당자
      - contact_phone: 연락처 (전화번호)

      ### 건명/품목
      - project_name: 건명 또는 품목 요약 (견적서 상단에 기재된 건명)

      ### 내역 항목 (items 배열)
      각 항목에 대해:
      - name: 품명
      - spec: 규격/사양
      - unit: 단위 (예: "개", "EA", "식", "m²")
      - qty: 수량 (숫자)
      - unit_price: 단가 (숫자, 원 단위)

      ### 금액
      - supply_amount: 공급가액 (숫자, 원 단위)
      - vat_amount: 부가세 (숫자, 원 단위)
      - total_amount: 합계금액 (숫자, 원 단위)

      ### 계약 구분
      - contract_type: 계약 유형을 품목 내용으로 판단하여 "물품", "용역", "공사" 중 하나로 표기
        - 물품: 물건·장비·비품·소모품 구매 (예: 에어컨, 노트북, 사무용품)
        - 용역: 서비스·연구·개발·컨설팅·유지보수·SW개발 (예: 홈페이지 제작, 연구용역, 시스템 유지보수)
        - 공사: 시설물 설치·철거·보수·건축·토목 (예: 도장공사, 방수공사, 칸막이 설치)

      ### 사업 필요성
      - necessity: 견적서의 품목/건명을 바탕으로 공공기관 사업계획서에 들어갈 사업 필요성 문장을 1~2문장으로 생성.
        - 예시: "기존 냉난방기의 노후화로 냉방효율이 저하되어 교체가 필요함"
        - 예시: "업무용 PC의 성능 저하로 업무 효율이 떨어져 교체 필요"
        - 예시: "시설물 노후화에 따른 안전사고 예방 및 쾌적한 업무환경 조성을 위해 보수공사가 필요함"

      ### 기타
      - quote_date: 견적일자 (YYYY-MM-DD 형식)
      - validity_period: 견적 유효기간
      - delivery_period: 납품기한/납기
      - payment_terms: 결제조건
      - remarks: 비고/특이사항

      ## 규칙
      1. 문서에 명시적으로 있는 정보만 추출하세요. 단, contract_type과 necessity는 품목 내용을 바탕으로 판단/생성하세요.
      2. 추측하지 마세요. 없는 정보는 null로 표기하세요.
      3. 금액(supply_amount, vat_amount, total_amount, unit_price, qty)은 반드시 JSON 숫자 타입으로 출력하세요. 문자열이 아닌 숫자입니다.
         - 올바른 예: "unit_price": 15000000, "qty": 2
         - 잘못된 예: "unit_price": "15,000,000", "qty": "2"
         - 쉼표, "원", "개" 등 단위 문자를 포함하지 마세요.
      4. items에는 실제 품목만 포함. 소계/합계/부가세 행은 제외하세요.
      5. 수량과 단가를 알 수 없으면 qty: 0, unit_price: 0으로 표기하세요.
      6. project_name이 없으면 품목들을 종합하여 간단히 요약하세요.
      7. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "company_name": "...",
        "business_no": "...",
        "representative": "...",
        "contact_person": "...",
        "contact_phone": "...",
        "project_name": "...",
        "contract_type": "물품",
        "necessity": "...",
        "items": [
          { "name": "...", "spec": "...", "unit": "EA", "qty": 10, "unit_price": 50000 }
        ],
        "supply_amount": 500000,
        "vat_amount": 50000,
        "total_amount": 550000,
        "quote_date": "2026-01-15",
        "validity_period": "...",
        "delivery_period": "...",
        "payment_terms": "...",
        "remarks": "..."
      }
      ```
    PROMPT
  end

  def build_task_extraction_prompt(extracted_text = nil)
    text_section = if extracted_text
      "## 추출된 문서 텍스트\n#{extracted_text}"
    else
      "## 첨부 이미지\n위 이미지는 공문(관공서 공식 문서)입니다."
    end

    <<~PROMPT
      당신은 한국 공공기관 공문서에서 업무 일정을 추출하는 전문가입니다.

      아래 공문에서 수행해야 할 업무(할 일)와 그 기한(날짜)을 추출해주세요.

      #{text_section}

      ## 추출 규칙
      1. 문서에 명시적으로 언급된 업무와 날짜만 추출하세요.
      2. 추측하지 마세요.
      3. 날짜는 반드시 YYYY-MM-DD 형식으로 변환하세요.
      4. 시간이 명시되어 있으면 HH:MM (24시간) 형식으로 포함하세요. 없으면 null.
      5. 각 업무에 적합한 분류를 다음 중에서 선택하세요:
         급여, 세무, 보험, 회계, 보고, 서무, 복지
         적합한 것이 없으면 "서무"로 지정하세요.
      6. 반드시 JSON 형식으로만 응답하세요.

      ## 응답 형식
      ```json
      {
        "document_title": "공문 제목 또는 요약",
        "tasks": [
          {
            "title": "구체적인 업무 내용",
            "date": "2026-03-15",
            "time": "14:00",
            "cat": "보고"
          }
        ]
      }
      ```
    PROMPT
  end
end
