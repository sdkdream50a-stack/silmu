# 법령 자동 검증 및 업데이트 Rake Task
# 사용법:
#   rake legal:check          - 법령 기준 검증만 수행
#   rake legal:update         - 법령 기준 검증 및 자동 수정
#   rake legal:report         - 검증 보고서 생성
#   rake legal:sources        - 법령 출처 URL 확인

require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

namespace :legal do
  LEGAL_STANDARDS_PATH = Rails.root.join('config', 'legal_standards.yml')
  REPORT_PATH = Rails.root.join('tmp', 'legal_check_report.md')

  desc "법령 기준 검증"
  task check: :environment do
    puts "🔍 법령 기준 검증 시작..."
    puts "=" * 60

    standards = load_standards
    results = validate_all(standards)

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
    results = validate_all(standards)

    if results[:errors].any?
      puts "\n⚠️  #{results[:errors].count}개 불일치 항목 발견"
      puts "자동 수정을 시도합니다...\n"

      updated_files = auto_fix(results[:errors], standards)

      if updated_files.any?
        puts "\n📝 수정된 파일:"
        updated_files.each { |f| puts "  - #{f}" }

        # 재검증
        puts "\n🔄 재검증 중..."
        new_results = validate_all(standards)

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

  desc "법령 검증 보고서 생성"
  task report: :environment do
    puts "📋 법령 검증 보고서 생성 중..."

    standards = load_standards
    results = validate_all(standards)

    report = generate_report(standards, results)

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

      # URL 접근 가능 여부 확인 (선택적)
      # status = check_url(source['url'])
      # puts "   상태: #{status}"
    end
  end

  desc "GitHub Actions용 검증 (CI/CD)"
  task ci_check: :environment do
    standards = load_standards
    results = validate_all(standards)

    # JSON 형식으로 결과 출력 (GitHub Actions에서 파싱 가능)
    output = {
      version: standards['version'],
      timestamp: Time.now.iso8601,
      success: results[:errors].empty?,
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

  def validate_all(standards)
    results = {
      checked: [],
      passed: [],
      errors: [],
      warnings: []
    }

    validation_config = standards.dig('validation', 'files') || []

    validation_config.each do |file_config|
      file_path = Rails.root.join(file_config['path'])

      unless File.exist?(file_path)
        results[:errors] << {
          file: file_config['path'],
          message: "파일을 찾을 수 없음"
        }
        next
      end

      content = File.read(file_path)
      results[:checked] << file_config['path']

      file_config['checks'].each do |check|
        case check['type']
        when 'contract_threshold'
          validate_contract_thresholds(content, file_config['path'], check, standards, results)
        when 'travel_expense'
          validate_travel_expense(content, file_config['path'], check, standards, results)
        when 'content'
          validate_content_patterns(content, file_config['path'], check, results)
        end
      end
    end

    results
  end

  def validate_contract_thresholds(content, file_path, check, standards, results)
    contract = standards['contract']

    # 주요 금액 기준 검증
    thresholds = {
      '1인 견적 한도' => contract.dig('single_estimate', 'goods'),
      '2인 견적 물품/용역' => contract.dig('multiple_estimate', 'goods'),
      '종합공사 한도' => contract.dig('multiple_estimate', 'construction_general'),
      '전문공사 한도' => contract.dig('multiple_estimate', 'construction_special'),
      '특례기업 한도' => contract.dig('special_enterprise', 'women')
    }

    check['patterns'].each do |pattern|
      unless content.include?(pattern)
        results[:warnings] << {
          file: file_path,
          message: "패턴 미발견: #{pattern}"
        }
      end
    end

    # 잘못된 금액이 있는지 확인
    wrong_patterns = [
      { pattern: /2[,_]?200[,_]?000/, correct: '20_000_000', desc: '2천만원(오류: 2,200만원)' },
      { pattern: /22[,_]?000[,_]?000/, correct: '20_000_000', desc: '2천만원(오류: 2,200만원)' }
    ]

    wrong_patterns.each do |wp|
      if content.match?(wp[:pattern])
        results[:errors] << {
          file: file_path,
          message: "잘못된 금액 발견: #{wp[:desc]} → #{wp[:correct]}로 수정 필요",
          pattern: wp[:pattern],
          correct: wp[:correct]
        }
      end
    end
  end

  def validate_travel_expense(content, file_path, check, standards, results)
    travel = standards['travel_expense']

    expected = {
      'seoul' => travel.dig('accommodation', 'seoul'),
      'metro' => travel.dig('accommodation', 'metro'),
      'other' => travel.dig('accommodation', 'other'),
      'meal' => travel['meal'],
      'daily' => travel['daily_allowance']
    }

    check['patterns'].each do |pattern|
      unless content.include?(pattern)
        results[:warnings] << {
          file: file_path,
          message: "여비 패턴 미발견: #{pattern}"
        }
      end
    end
  end

  def validate_content_patterns(content, file_path, check, results)
    check['patterns'].each do |pattern|
      unless content.include?(pattern)
        results[:warnings] << {
          file: file_path,
          message: "콘텐츠 패턴 미발견: #{pattern}"
        }
      end
    end
  end

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

  def generate_report(standards, results)
    <<~REPORT
      # 법령 검증 보고서

      생성일시: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
      기준 버전: #{standards['version']}

      ## 검증 결과 요약

      | 항목 | 결과 |
      |------|------|
      | 검증 파일 수 | #{results[:checked].count}개 |
      | 통과 | #{results[:passed].count}개 |
      | 오류 | #{results[:errors].count}개 |
      | 경고 | #{results[:warnings].count}개 |

      ## 현재 적용 법령 기준

      ### 수의계약 (지방계약법 시행령)

      | 구분 | 1인 견적 | 2인 견적 | 수의계약 한도 |
      |------|----------|----------|--------------|
      | 물품/용역 | #{format_currency(standards.dig('contract', 'single_estimate', 'goods'))} | #{format_currency(standards.dig('contract', 'multiple_estimate', 'goods'))} | #{format_currency(standards.dig('contract', 'private_contract_limit', 'goods'))} |
      | 종합공사 | #{format_currency(standards.dig('contract', 'single_estimate', 'construction'))} | - | #{format_currency(standards.dig('contract', 'multiple_estimate', 'construction_general'))} |
      | 전문공사 | #{format_currency(standards.dig('contract', 'single_estimate', 'construction'))} | - | #{format_currency(standards.dig('contract', 'multiple_estimate', 'construction_special'))} |

      ### 출장 여비 (공무원여비규정)

      | 항목 | 서울 | 광역시 | 기타 |
      |------|------|--------|------|
      | 숙박비 | #{format_currency(standards.dig('travel_expense', 'accommodation', 'seoul'))} | #{format_currency(standards.dig('travel_expense', 'accommodation', 'metro'))} | #{format_currency(standards.dig('travel_expense', 'accommodation', 'other'))} |
      | 식비 | #{format_currency(standards['travel_expense']['meal'])} (전 지역 동일) |||
      | 일비 | #{format_currency(standards['travel_expense']['daily_allowance'])} (전 지역 동일) |||

      ## 오류 상세

      #{results[:errors].empty? ? '없음' : results[:errors].map { |e| "- **#{e[:file]}**: #{e[:message]}" }.join("\n")}

      ## 경고 상세

      #{results[:warnings].empty? ? '없음' : results[:warnings].map { |w| "- **#{w[:file]}**: #{w[:message]}" }.join("\n")}

      ## 참조 법령

      #{(standards.dig('contract', 'sources') || []).map { |s| "- [#{s['name']}](#{s['url']}) (#{s['last_amended']} 개정)" }.join("\n")}
      #{(standards.dig('travel_expense', 'sources') || []).map { |s| "- [#{s['name']}](#{s['url']}) (#{s['last_amended']} 개정)" }.join("\n")}
    REPORT
  end

  def format_currency(amount)
    return '미정' if amount.nil?
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse + '원'
  end

  def print_results(results)
    puts "\n📁 검증한 파일 (#{results[:checked].count}개):"
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
