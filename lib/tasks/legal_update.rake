# 법령 자동 검증 및 업데이트 Rake Task (개선판 v2)
#
# 주요 개선사항:
# - 파일 자동 스캔 (새 파일 추가 시 자동 포함)
# - 법령 키워드 기반 전체 검색
# - 금액 패턴 자동 감지 및 검증
#
# 사용법:
#   rake legal:check          - 법령 기준 검증만 수행
#   rake legal:update         - 법령 기준 검증 및 자동 수정
#   rake legal:report         - 검증 보고서 생성
#   rake legal:scan           - 법령 관련 파일 스캔 (새 파일 발견)
#   rake legal:sources        - 법령 출처 URL 확인

require 'yaml'
require 'json'
require 'fileutils'

namespace :legal do
  LEGAL_STANDARDS_PATH = Rails.root.join('config', 'legal_standards.yml')
  REPORT_PATH = Rails.root.join('tmp', 'legal_check_report.md')

  # 자동 스캔 대상 디렉토리 및 파일 패턴
  AUTO_SCAN_PATTERNS = [
    'app/controllers/**/*.rb',
    'app/services/**/*.rb',
    'app/views/**/*.erb',
    'app/views/**/*.html.erb',
    'db/seeds/**/*.rb',
    'lib/**/*.rb',
    'config/locales/**/*.yml'
  ].freeze

  # 법령 관련 키워드 (이 키워드가 포함된 파일만 검증)
  LEGAL_KEYWORDS = [
    # 금액 관련
    '천만원', '억원', '만원',
    '20_000_000', '50_000_000', '100_000_000', '400_000_000', '200_000_000', '160_000_000',
    '20000000', '50000000', '100000000', '400000000',
    # 계약 관련
    '수의계약', '1인 견적', '2인 견적', '소액수의', '경쟁입찰',
    '지방계약법', '시행령',
    # 여비 관련
    '숙박비', '식비', '일비', '여비', '출장비',
    'accommodation', 'meal', 'daily',
    # 기타 법령
    '공무원여비규정', '건설산업기본법', '중소기업'
  ].freeze

  # 잘못된 금액 패턴 (자동 감지 및 수정)
  WRONG_AMOUNT_PATTERNS = [
    # 수의계약 금액 오류
    { pattern: /2[,_]?200[,_]?000(?!\d)/, correct: '20_000_000', desc: '2천만원 (오류: 2,200만원)' },
    { pattern: /22[,_]?000[,_]?000(?!\d)/, correct: '20_000_000', desc: '2천만원 (오류: 2,200만원)' },
    { pattern: /5[,_]?500[,_]?000(?!\d)/, correct: '50_000_000', desc: '5천만원 (오류: 5,500만원)' },
    { pattern: /55[,_]?000[,_]?000(?!\d)/, correct: '50_000_000', desc: '5천만원 (오류: 5,500만원)' },
    # 텍스트 오류
    { pattern: /2,?200만원/, correct: '2천만원', desc: '2천만원 (오류: 2,200만원)' },
    { pattern: /2천2백만원/, correct: '2천만원', desc: '2천만원 (오류: 2천2백만원)' },
    { pattern: /5,?500만원/, correct: '5천만원', desc: '5천만원 (오류: 5,500만원)' },
    # 여비 금액 오류 (구 기준)
    { pattern: /숙박비[^0-9]*80[,_]?000(?!\d).*서울/m, correct: nil, desc: '서울 숙박비 확인 필요 (현행: 10만원)', warning_only: true },
  ].freeze

  # 올바른 금액 패턴 (이 패턴이 있어야 함)
  CORRECT_AMOUNT_PATTERNS = {
    contract: {
      single_estimate: ['20_000_000', '20000000', '2천만원', '2,000만원'],
      multiple_estimate_goods: ['50_000_000', '50000000', '5천만원', '5,000만원'],
      construction_general: ['400_000_000', '400000000', '4억원', '4억'],
      construction_special: ['200_000_000', '200000000', '2억원', '2억'],
      construction_etc: ['160_000_000', '160000000', '1억6천만원', '1억 6천만원']
    },
    travel: {
      seoul_accommodation: ['100_000', '100000', '10만원'],
      metro_accommodation: ['80_000', '80000', '8만원'],
      other_accommodation: ['70_000', '70000', '7만원'],
      meal: ['25_000', '25000', '2만5천원', '25,000'],
      daily: ['25_000', '25000', '2만5천원', '25,000']
    }
  }.freeze

  desc "법령 기준 검증 (자동 스캔)"
  task check: :environment do
    puts "🔍 법령 기준 검증 시작 (자동 스캔 모드)..."
    puts "=" * 60

    standards = load_standards
    files = scan_legal_files
    results = validate_all_files(files, standards)

    print_results(results)

    if results[:errors].any?
      puts "\n❌ 검증 실패: #{results[:errors].count}개 항목이 기준과 불일치"
      exit 1
    else
      puts "\n✅ 검증 완료: 모든 항목이 최신 법령 기준과 일치"
    end
  end

  desc "법령 기준 검증 및 자동 수정"
  task update: :environment do
    puts "🔄 법령 자동 업데이트 시작..."
    puts "=" * 60

    standards = load_standards
    files = scan_legal_files
    results = validate_all_files(files, standards)

    if results[:errors].any?
      puts "\n⚠️  #{results[:errors].count}개 불일치 항목 발견"
      puts "자동 수정을 시도합니다...\n"

      updated_files = auto_fix(results[:errors], standards)

      if updated_files.any?
        puts "\n📝 수정된 파일:"
        updated_files.each { |f| puts "  - #{f}" }

        # 재검증
        puts "\n🔄 재검증 중..."
        new_results = validate_all_files(files, standards)

        if new_results[:errors].empty?
          puts "✅ 모든 수정이 완료되었습니다."
        else
          puts "⚠️  일부 항목은 수동 수정이 필요합니다:"
          new_results[:errors].each do |error|
            puts "  - #{error[:file]}: #{error[:message]}"
          end
        end
      else
        puts "❌ 자동 수정 불가. 수동 수정이 필요합니다."
      end
    else
      puts "✅ 모든 항목이 이미 최신 상태입니다."
    end
  end

  desc "법령 관련 파일 스캔 (새 파일 발견)"
  task scan: :environment do
    puts "📂 법령 관련 파일 스캔 중..."
    puts "=" * 60

    files = scan_legal_files
    registered_files = load_standards.dig('validation', 'files')&.map { |f| f['path'] } || []

    puts "\n🔍 발견된 법령 관련 파일 (#{files.count}개):\n"

    new_files = []
    files.each do |file|
      relative_path = file.sub("#{Rails.root}/", '')
      is_new = !registered_files.include?(relative_path)
      new_files << relative_path if is_new

      status = is_new ? "🆕 NEW" : "✓"
      puts "  #{status} #{relative_path}"
    end

    if new_files.any?
      puts "\n" + "=" * 60
      puts "⚠️  #{new_files.count}개의 새 파일이 발견되었습니다."
      puts "이 파일들은 자동으로 검증에 포함됩니다."
    end
  end

  desc "법령 검증 보고서 생성"
  task report: :environment do
    puts "📋 법령 검증 보고서 생성 중..."

    standards = load_standards
    files = scan_legal_files
    results = validate_all_files(files, standards)

    report = generate_report(standards, results, files)

    File.write(REPORT_PATH, report)
    puts "✅ 보고서 생성 완료: #{REPORT_PATH}"
  end

  desc "법령 출처 URL 확인"
  task sources: :environment do
    puts "🔗 법령 출처 URL 확인 중..."
    puts "=" * 60

    standards = load_standards

    all_sources = []
    all_sources += standards.dig('contract', 'sources') || []
    all_sources += standards.dig('travel_expense', 'sources') || []

    all_sources.each do |source|
      puts "\n📌 #{source['name']}"
      puts "   URL: #{source['url']}"
      puts "   최종 개정: #{source['last_amended']}"
    end
  end

  desc "GitHub Actions용 검증 (CI/CD)"
  task ci_check: :environment do
    standards = load_standards
    files = scan_legal_files
    results = validate_all_files(files, standards)

    output = {
      version: standards['version'],
      timestamp: Time.now.iso8601,
      success: results[:errors].empty?,
      scanned_files: files.count,
      checked_files: results[:checked].count,
      errors: results[:errors].map { |e| { file: e[:file], message: e[:message] } },
      warnings: results[:warnings].map { |w| { file: w[:file], message: w[:message] } }
    }

    puts output.to_json

    exit 1 if results[:errors].any?
  end

  private

  def load_standards
    unless File.exist?(LEGAL_STANDARDS_PATH)
      raise "법령 기준 파일을 찾을 수 없습니다: #{LEGAL_STANDARDS_PATH}"
    end

    YAML.load_file(LEGAL_STANDARDS_PATH)
  end

  # 법령 관련 파일 자동 스캔
  def scan_legal_files
    all_files = []

    AUTO_SCAN_PATTERNS.each do |pattern|
      Dir.glob(Rails.root.join(pattern)).each do |file|
        next if File.directory?(file)
        next if file.include?('/tmp/')
        next if file.include?('/log/')

        content = File.read(file) rescue next

        # 법령 키워드가 포함된 파일만 선택
        if LEGAL_KEYWORDS.any? { |keyword| content.include?(keyword) }
          all_files << file
        end
      end
    end

    all_files.uniq.sort
  end

  # 모든 파일 검증
  def validate_all_files(files, standards)
    results = {
      checked: [],
      passed: [],
      errors: [],
      warnings: []
    }

    files.each do |file_path|
      content = File.read(file_path) rescue next
      relative_path = file_path.sub("#{Rails.root}/", '')

      results[:checked] << relative_path

      # 1. 잘못된 금액 패턴 검사
      validate_wrong_patterns(content, relative_path, results)

      # 2. 파일 유형별 추가 검증
      case relative_path
      when /contract_method_service\.rb/
        validate_contract_service(content, relative_path, standards, results)
      when /chatbot_controller\.rb/
        validate_chatbot_controller(content, relative_path, standards, results)
      when /travel_calculator/
        validate_travel_calculator(content, relative_path, standards, results)
      when /seeds.*\.rb/
        validate_seed_file(content, relative_path, standards, results)
      when /\.erb$/
        validate_erb_file(content, relative_path, standards, results)
      end
    end

    results
  end

  # 잘못된 금액 패턴 검사
  def validate_wrong_patterns(content, file_path, results)
    WRONG_AMOUNT_PATTERNS.each do |wp|
      if content.match?(wp[:pattern])
        if wp[:warning_only]
          results[:warnings] << {
            file: file_path,
            message: wp[:desc]
          }
        else
          results[:errors] << {
            file: file_path,
            message: "잘못된 금액 발견: #{wp[:desc]}",
            pattern: wp[:pattern],
            correct: wp[:correct]
          }
        end
      end
    end
  end

  # 계약 서비스 파일 검증
  def validate_contract_service(content, file_path, standards, results)
    contract = standards['contract']

    # 주요 금액 확인
    checks = [
      { value: contract.dig('single_estimate', 'goods'), name: '1인 견적 한도 (물품)' },
      { value: contract.dig('multiple_estimate', 'goods'), name: '2인 견적 한도 (물품)' },
      { value: contract.dig('multiple_estimate', 'construction_general'), name: '종합공사 한도' }
    ]

    checks.each do |check|
      formatted = check[:value].to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1_')
      unless content.include?(formatted) || content.include?(check[:value].to_s)
        results[:warnings] << {
          file: file_path,
          message: "#{check[:name]} (#{formatted}) 패턴 미발견"
        }
      end
    end
  end

  # 챗봇 컨트롤러 검증
  def validate_chatbot_controller(content, file_path, standards, results)
    contract = standards['contract']

    # 수의계약 금액 기준 확인
    single_limit = contract.dig('single_estimate', 'goods')
    if content.include?('price <=') || content.include?('price >')
      formatted = single_limit.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1_')
      unless content.include?(formatted)
        results[:warnings] << {
          file: file_path,
          message: "1인 견적 기준 금액 확인 필요 (현행: #{formatted})"
        }
      end
    end
  end

  # 출장비 계산기 검증
  def validate_travel_calculator(content, file_path, standards, results)
    travel = standards['travel_expense']

    # 숙박비 확인
    accommodations = {
      'seoul' => travel.dig('accommodation', 'seoul'),
      'metro' => travel.dig('accommodation', 'metro'),
      'other' => travel.dig('accommodation', 'other')
    }

    accommodations.each do |region, amount|
      # JavaScript 형식 확인
      js_pattern = "'#{region}': #{amount}"
      alt_pattern = "#{region}: #{amount}"

      unless content.include?(js_pattern) || content.include?(alt_pattern) || content.include?(amount.to_s)
        results[:warnings] << {
          file: file_path,
          message: "#{region} 숙박비 (#{amount}원) 패턴 미발견"
        }
      end
    end

    # 식비, 일비 확인
    meal = travel['meal']
    daily = travel['daily_allowance']

    unless content.include?("meal: #{meal}") || content.include?(meal.to_s)
      results[:warnings] << {
        file: file_path,
        message: "식비 (#{meal}원) 패턴 미발견"
      }
    end
  end

  # 시드 파일 검증
  def validate_seed_file(content, file_path, standards, results)
    # 텍스트 금액 표기 검증
    if content.include?('억원') || content.include?('천만원')
      # 종합공사 4억원
      unless content.include?('4억원') || content.include?('4억')
        if content.include?('종합공사') || content.include?('종합')
          results[:warnings] << {
            file: file_path,
            message: "종합공사 수의계약 한도 (4억원) 확인 필요"
          }
        end
      end

      # 1인 견적 2천만원
      if content.include?('1인 견적') && !content.include?('2천만원')
        results[:warnings] << {
          file: file_path,
          message: "1인 견적 기준 (2천만원) 확인 필요"
        }
      end
    end
  end

  # ERB 파일 검증
  def validate_erb_file(content, file_path, standards, results)
    # 금액이 포함된 ERB 파일 검증
    if content.match?(/\d{1,3}(,\d{3})*만원/) || content.match?(/\d+억/)
      # 잘못된 금액 표기가 있는지 확인
      validate_wrong_patterns(content, file_path, results)
    end
  end

  # 자동 수정
  def auto_fix(errors, standards)
    updated_files = []

    errors.each do |error|
      next unless error[:pattern] && error[:correct]

      file_path = Rails.root.join(error[:file])
      next unless File.exist?(file_path)

      content = File.read(file_path)
      new_content = content.gsub(error[:pattern], error[:correct])

      if content != new_content
        File.write(file_path, new_content)
        updated_files << error[:file]
        puts "  ✓ #{error[:file]} 수정됨"
      end
    end

    updated_files.uniq
  end

  # 보고서 생성
  def generate_report(standards, results, files)
    <<~REPORT
      # 법령 검증 보고서

      생성일시: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
      기준 버전: #{standards['version']}

      ## 검증 결과 요약

      | 항목 | 결과 |
      |------|------|
      | 스캔된 파일 수 | #{files.count}개 |
      | 검증된 파일 수 | #{results[:checked].count}개 |
      | 오류 | #{results[:errors].count}개 |
      | 경고 | #{results[:warnings].count}개 |

      ## 스캔된 파일 목록

      #{results[:checked].map { |f| "- #{f}" }.join("\n")}

      ## 현재 적용 법령 기준

      ### 수의계약 (지방계약법 시행령)

      | 구분 | 1인 견적 | 2인 견적/한도 |
      |------|----------|--------------|
      | 물품/용역 | #{format_currency(standards.dig('contract', 'single_estimate', 'goods'))} | #{format_currency(standards.dig('contract', 'multiple_estimate', 'goods'))} |
      | 종합공사 | #{format_currency(standards.dig('contract', 'single_estimate', 'construction'))} | #{format_currency(standards.dig('contract', 'multiple_estimate', 'construction_general'))} |
      | 전문공사 | #{format_currency(standards.dig('contract', 'single_estimate', 'construction'))} | #{format_currency(standards.dig('contract', 'multiple_estimate', 'construction_special'))} |
      | 전기/소방/정보통신 | #{format_currency(standards.dig('contract', 'single_estimate', 'construction'))} | #{format_currency(standards.dig('contract', 'multiple_estimate', 'construction_etc'))} |

      ### 출장 여비 (공무원여비규정)

      | 항목 | 서울 | 광역시 | 기타 |
      |------|------|--------|------|
      | 숙박비 | #{format_currency(standards.dig('travel_expense', 'accommodation', 'seoul'))} | #{format_currency(standards.dig('travel_expense', 'accommodation', 'metro'))} | #{format_currency(standards.dig('travel_expense', 'accommodation', 'other'))} |
      | 식비 | #{format_currency(standards.dig('travel_expense', 'meal'))} (전 지역 동일) |||
      | 일비 | #{format_currency(standards.dig('travel_expense', 'daily_allowance'))} (전 지역 동일) |||

      ## 오류 상세

      #{results[:errors].empty? ? '없음' : results[:errors].map { |e| "- **#{e[:file]}**: #{e[:message]}" }.join("\n")}

      ## 경고 상세

      #{results[:warnings].empty? ? '없음' : results[:warnings].map { |w| "- **#{w[:file]}**: #{w[:message]}" }.join("\n")}

      ## 참조 법령

      #{(standards.dig('contract', 'sources') || []).map { |s| "- [#{s['name']}](#{s['url']}) (#{s['last_amended']} 개정)" }.join("\n")}
      #{(standards.dig('travel_expense', 'sources') || []).map { |s| "- [#{s['name']}](#{s['url']}) (#{s['last_amended']} 개정)" }.join("\n")}

      ---
      *이 보고서는 자동 생성되었습니다.*
    REPORT
  end

  def format_currency(amount)
    return '미정' if amount.nil?
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse + '원'
  end

  def print_results(results)
    puts "\n📂 스캔 및 검증한 파일 (#{results[:checked].count}개):"
    results[:checked].each { |f| puts "  - #{f}" }

    if results[:errors].any?
      puts "\n❌ 오류 (#{results[:errors].count}개):"
      results[:errors].each { |e| puts "  - #{e[:file]}: #{e[:message]}" }
    end

    if results[:warnings].any?
      puts "\n⚠️  경고 (#{results[:warnings].count}개):"
      results[:warnings].each { |w| puts "  - #{w[:file]}: #{w[:message]}" }
    end
  end
end
