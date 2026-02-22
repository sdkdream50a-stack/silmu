# frozen_string_literal: true

# 법규정 자동 검증 서비스 (법령검증팀 체크리스트 통합)
# Anthropic API를 사용하여 토픽 콘텐츠 + 실무 도구가 현행 규정과 일치하는지 검증
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

  # 도구별 검증 항목
  TOOL_VERIFICATIONS = {
    'travel_calculator' => {
      file: 'app/views/tools/travel_calculator.html.erb',
      checks: ['숙박비: 서울 7만원, 광역시 6만원, 기타 5만원 (2026.01.02 시행)']
    },
    'estimated_price' => {
      file: 'app/services/estimated_price_service.rb',
      checks: [
        '수의계약 한도: 물품/용역 2천만원, 공사 2억원 (전문공사 기준)',
        '견적 요건: 2백만원 이하 생략 가능, 2천만원 이하 1인 견적',
        '이윤율 상한: 용역 10%, 공사 15%',
        '일반관리비 상한: 8%'
      ]
    },
    'contract_reason' => {
      file: 'app/views/contract_reasons/index.html.erb',
      checks: ['공사 금액: 종합 4억, 전문 2억, 기타 1.6억']
    },
    'legal_period' => {
      file: 'app/services/legal_period_service.rb',
      checks: ['입찰공고: 10억 미만 7일, 10억~50억 15일, 50억 이상 40일']
    }
  }.freeze

  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    @changes = []
    @errors = []
  end

  # 모든 토픽 + 도구 검증
  def verify_all
    log "=" * 60
    log "법규정 자동 검증 시작 (법령검증팀 체크리스트 통합): #{Time.current}"
    log "=" * 60

    # 1. 토픽 검증
    log "\n📋 토픽 검증 시작..."
    Topic.published.find_each do |topic|
      verify_topic(topic)
    end

    # 2. 도구 검증
    log "\n🛠️ 도구 검증 시작..."
    verify_tools

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

  def verify_tools
    TOOL_VERIFICATIONS.each do |tool_name, config|
      verify_tool(tool_name, config)
    end
  end

  def verify_tool(tool_name, config)
    log "\n[#{tool_name}] 도구 검증 중..."

    file_path = Rails.root.join(config[:file])
    unless File.exist?(file_path)
      log "  ⚠️ 파일 없음: #{config[:file]}"
      return
    end

    content = File.read(file_path)
    checks = config[:checks]

    begin
      prompt = build_tool_verification_prompt(tool_name, content, checks)
      response = call_anthropic_api(prompt)

      return unless response

      if response[:needs_update] && response[:corrections].present?
        log "  ❌ 오류 발견: #{response[:corrections].count}건"
        response[:corrections].each do |correction|
          @errors << {
            tool: tool_name,
            file: config[:file],
            wrong_value: correction[:wrong_value],
            correct_value: correction[:correct_value],
            reason: correction[:reason],
            source: correction[:source]
          }
          log "    • #{correction[:wrong_value]} → #{correction[:correct_value]}"
          log "      근거: #{correction[:source]}"
        end
      else
        log "  ✓ 정상: 현행 규정과 일치"
      end

    rescue => e
      @errors << { tool: tool_name, error: e.message }
      log "  ❌ 검증 오류: #{e.message}"
    end
  end

  def build_tool_verification_prompt(tool_name, content, checks)
    <<~PROMPT
      당신은 한국 공무원 행정 규정 전문가입니다.

      다음 도구 코드가 2026년 현재 시행 중인 최신 법규정과 일치하는지 검증해주세요.

      ## 검증 대상 도구
      #{tool_name}

      ## 필수 확인 사항
      #{checks.map { |c| "- #{c}" }.join("\n")}

      ## 코드 내용 (일부)
      #{content[0..5000]}

      ## 검증 요청
      1. 위 필수 확인 사항이 코드에 정확히 반영되어 있는지 확인
      2. 금액, 기간, 비율 등이 현행 규정과 일치하는지 확인
      3. 오류가 있다면 구체적으로 어떤 값이 잘못되었고, 올바른 값이 무엇인지 제시
      4. 근거 법령/규정 명시

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

      ## 법령검증팀 체크리스트 (CRITICAL)

      ### A. 법령 출처 검증
      - ✅ 법제처 국가법령정보센터 (law.go.kr)
      - ✅ 행정안전부 예규 (mois.go.kr)
      - ✅ 조달청 공식 자료 (pps.go.kr)

      ### B. 법령 체계 검증 (CRITICAL)
      - law_content = 법률만 (예: 지방계약법 제9조)
      - decree_content = 시행령 (예: 지방계약법 시행령 제25조)
      - rule_content = 시행규칙/지침

      ### C. 조문 번호 검증 (CRITICAL)
      - 수의계약 한도: 시행령 제25조 (❌ 제30조 아님)
      - 견적 절차: 시행령 제30조 (❌ 제25조 아님)
      - 분할계약 금지: 시행령 제77조
      - 입찰보증금: 시행령 제12조 (❌ 제9조 아님)
      - 지체상금/지연배상금: 시행령 제90조 (❌ 제74조 아님)

      ### D. 금액 기준 검증 (CRITICAL)

      **수의계약 한도** (시행령 제25조):
      - 공사 - 종합공사: 4억원 이하 ✅
      - 공사 - 전문공사: 2억원 이하 ✅
      - 공사 - 기타공사: 1.6억원 이하 ✅
      - 물품/용역 - 일반: 2천만원 이하 ✅
      - 물품/용역 - 청년창업: 5천만원 이하 ✅

      **1인/2인 견적 기준** (시행령 제30조):
      - 1인 견적: 2천만원 이하 (일반), 5천만원 이하 (특례) ✅
      - 2인 이상 견적: 2천만원 초과 ✅

      **입찰 관련 기준**:
      - 입찰공고 기간: 10억 미만(7일), 10억~50억(15일), 50억 이상(40일) ✅
      - 복수예비가격: 2억원 이상 ✅

      ## 검증 요청
      1. 위 체크리스트 기준으로 콘텐츠 검증
      2. 법령 체계가 올바른지 확인 (#{field}에 맞는 법령만 있는지)
      3. 조문 번호가 정확한지 확인
      4. 금액, 기간, 비율이 현행 규정과 일치하는지 확인
      5. 오류가 있다면 구체적으로 제시
      6. 근거 법령/규정 명시

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
    log "검증 완료 (법령검증팀 체크리스트 기반): #{Time.current}"
    log "=" * 60

    # 토픽 변경사항
    topic_changes = @changes.select { |c| c[:topic] }
    # 도구 오류
    tool_errors = @errors.select { |e| e[:tool] }
    # 기타 오류
    other_errors = @errors.reject { |e| e[:tool] }

    if topic_changes.any?
      log "\n📝 토픽 수정된 항목: #{topic_changes.count}건"
      topic_changes.each do |change|
        log "  - [#{change[:topic]}] #{change[:field]}: #{change[:wrong_value]} → #{change[:correct_value]}"
      end
    else
      log "\n✅ 토픽: 수정 필요 항목 없음"
    end

    if tool_errors.any?
      log "\n🛠️ 도구 오류 발견: #{tool_errors.count}건"
      tool_errors.each do |error|
        log "  - [#{error[:tool]}] #{error[:file]}"
        log "    • #{error[:wrong_value]} → #{error[:correct_value]}" if error[:wrong_value]
        log "    근거: #{error[:source]}" if error[:source]
      end
    else
      log "\n✅ 도구: 오류 없음"
    end

    if other_errors.any?
      log "\n⚠️ 기타 오류: #{other_errors.count}건"
      other_errors.each do |error|
        if error[:topic]
          log "  - [#{error[:topic]}] #{error[:field]}: #{error[:error]}"
        else
          log "  - #{error[:error]}"
        end
      end
    end

    # 리포트 파일 저장
    save_report

    {
      changes: @changes,
      errors: @errors,
      summary: {
        topic_changes: topic_changes.count,
        tool_errors: tool_errors.count,
        other_errors: other_errors.count
      }
    }
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
