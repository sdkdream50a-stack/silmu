# frozen_string_literal: true

# 법규정 자동 검증 서비스
# Anthropic API를 사용하여 토픽 콘텐츠가 현행 규정과 일치하는지 검증
class RegulationVerifier
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  # 검증 대상 필드
  VERIFIABLE_FIELDS = %i[
    law_content
    decree_content
    rule_content
    regulation_content
    practical_tips
  ].freeze

  # 토픽별 검증 키워드
  TOPIC_KEYWORDS = {
    'travel-expense' => ['공무원 여비 규정', '출장비', '일비', '숙박비', '식비'],
    'year-end-settlement' => ['연말정산', '소득세법', '세액공제', '소득공제'],
    'budget-carryover' => ['예산이월', '지방재정법', '사고이월', '명시이월'],
    'private-contract' => ['수의계약', '지방계약법', '추정가격'],
    'private-contract-limit' => ['수의계약 한도', '지방계약법 시행령'],
    'single-quote' => ['1인견적', '수의계약'],
    'dual-quote' => ['2인 이상 견적', '2인견적', '나라장터', '지정정보처리장치'],
    'emergency-contract' => ['긴급수의', '긴급계약'],
    'price-negotiation' => ['수의시담', '가격협상']
  }.freeze

  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    @changes = []
    @errors = []
  end

  # 모든 토픽 검증
  def verify_all
    log "=" * 60
    log "법규정 자동 검증 시작: #{Time.current}"
    log "=" * 60

    Topic.published.find_each do |topic|
      verify_topic(topic)
    end

    generate_report
  end

  # 단일 토픽 검증
  def verify_topic(topic)
    log "\n[#{topic.slug}] #{topic.name} 검증 중..."

    keywords = TOPIC_KEYWORDS[topic.slug] || [topic.name]

    VERIFIABLE_FIELDS.each do |field|
      content = topic.send(field)
      next if content.blank?

      begin
        verify_field(topic, field, content, keywords)
      rescue => e
        @errors << { topic: topic.slug, field: field, error: e.message }
        log "  ❌ #{field} 검증 오류: #{e.message}"
      end
    end
  end

  private

  def verify_field(topic, field, content, keywords)
    return unless @api_key.present?

    # 콘텐츠에서 숫자/금액/날짜 추출
    numbers_in_content = extract_key_values(content)
    return if numbers_in_content.empty?

    log "  📋 #{field}: #{numbers_in_content.first(3).join(', ')}..."

    # AI에게 검증 요청
    prompt = build_verification_prompt(topic.name, field, content, keywords)
    response = call_anthropic_api(prompt)

    return unless response

    # 응답 파싱 및 수정 필요 여부 확인
    if response[:needs_update] && response[:corrections].present?
      apply_corrections(topic, field, content, response[:corrections])
    else
      log "  ✓ #{field}: 현행 규정과 일치"
    end
  end

  def extract_key_values(content)
    values = []

    # 금액 추출 (원, 만원, 억원)
    values += content.scan(/\d{1,3}(?:,\d{3})*(?:원|만원|억원)/)
    values += content.scan(/\d+천만원/)

    # 퍼센트 추출
    values += content.scan(/\d+(?:\.\d+)?%/)

    # 날짜 추출
    values += content.scan(/\d{4}년\s*\d{1,2}월\s*\d{1,2}일/)
    values += content.scan(/\d{1,2}월\s*\d{1,2}일/)

    # 기간 추출
    values += content.scan(/\d+일\s*이내/)
    values += content.scan(/\d+주일?\s*이내/)

    values.uniq
  end

  def build_verification_prompt(topic_name, field, content, keywords)
    <<~PROMPT
      당신은 한국 공무원 행정 규정 전문가입니다.

      다음 콘텐츠가 2026년 현재 시행 중인 최신 법규정과 일치하는지 검증해주세요.

      ## 검증 대상
      - 토픽: #{topic_name}
      - 필드: #{field}
      - 관련 키워드: #{keywords.join(', ')}

      ## 콘텐츠
      #{content[0..3000]}

      ## 검증 요청
      1. 위 콘텐츠에 포함된 금액, 기간, 비율 등이 현행 규정과 일치하는지 확인
      2. 오류가 있다면 구체적으로 어떤 값이 잘못되었고, 올바른 값이 무엇인지 제시
      3. 근거 법령/규정 명시

      ## 응답 형식 (JSON)
      {
        "needs_update": true/false,
        "corrections": [
          {
            "wrong_value": "잘못된 값",
            "correct_value": "올바른 값",
            "reason": "수정 이유",
            "source": "근거 법령"
          }
        ],
        "summary": "검증 결과 요약"
      }

      JSON 형식으로만 응답해주세요.
    PROMPT
  end

  def call_anthropic_api(prompt)
    return nil unless @api_key

    uri = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = @api_key
    request['anthropic-version'] = '2023-06-01'

    request.body = {
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 2000,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      content = result.dig('content', 0, 'text')
      parse_ai_response(content)
    else
      log "  ⚠️ API 오류: #{response.code}"
      nil
    end
  rescue => e
    log "  ⚠️ API 호출 실패: #{e.message}"
    nil
  end

  def parse_ai_response(content)
    return nil if content.blank?

    # JSON 블록 추출
    json_match = content.match(/\{[\s\S]*\}/)
    return nil unless json_match

    JSON.parse(json_match[0], symbolize_names: true)
  rescue JSON::ParserError
    nil
  end

  def apply_corrections(topic, field, content, corrections)
    updated_content = content.dup

    corrections.each do |correction|
      wrong = correction[:wrong_value]
      correct = correction[:correct_value]

      if updated_content.include?(wrong)
        updated_content.gsub!(wrong, correct)

        change = {
          topic: topic.slug,
          field: field,
          wrong_value: wrong,
          correct_value: correct,
          reason: correction[:reason],
          source: correction[:source]
        }
        @changes << change

        log "  🔧 수정: #{wrong} → #{correct}"
        log "     근거: #{correction[:source]}"
      end
    end

    if updated_content != content
      topic.update!(field => updated_content)
      log "  💾 #{field} 저장 완료"
    end
  end

  def generate_report
    log "\n" + "=" * 60
    log "검증 완료: #{Time.current}"
    log "=" * 60

    if @changes.any?
      log "\n📝 수정된 항목: #{@changes.count}건"
      @changes.each do |change|
        log "  - [#{change[:topic]}] #{change[:field]}: #{change[:wrong_value]} → #{change[:correct_value]}"
      end
    else
      log "\n✅ 수정 필요 항목 없음"
    end

    if @errors.any?
      log "\n⚠️ 오류 발생: #{@errors.count}건"
      @errors.each do |error|
        log "  - [#{error[:topic]}] #{error[:field]}: #{error[:error]}"
      end
    end

    # 리포트 파일 저장
    save_report

    { changes: @changes, errors: @errors }
  end

  def save_report
    report_dir = Rails.root.join('log', 'regulation_reports')
    FileUtils.mkdir_p(report_dir)

    report_file = report_dir.join("report_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json")

    report = {
      timestamp: Time.current.iso8601,
      changes: @changes,
      errors: @errors,
      summary: {
        total_changes: @changes.count,
        total_errors: @errors.count
      }
    }

    File.write(report_file, JSON.pretty_generate(report))
    log "\n📄 리포트 저장: #{report_file}"
  end

  def log(message)
    puts message
    Rails.logger.info(message) if defined?(Rails)
  end
end
