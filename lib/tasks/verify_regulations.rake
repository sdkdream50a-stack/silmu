# frozen_string_literal: true

namespace :verify do
  desc "법규정 검증 및 자동 수정 (전체 토픽)"
  task regulations: :environment do
    puts "🔍 법규정 자동 검증 시작..."

    # API 키 확인
    unless ENV["ANTHROPIC_API_KEY"].present?
      puts "⚠️ ANTHROPIC_API_KEY 환경변수가 설정되지 않았습니다."
      puts "   export ANTHROPIC_API_KEY='your-api-key'"
      exit 1
    end

    # 검증 실행
    verifier = RegulationVerifier.new
    result = verifier.verify_all

    # 변경사항이 있으면 Git 커밋 및 푸시
    if result[:changes].any?
      puts "\n🔄 Git 커밋 및 푸시 중..."

      # 데이터베이스 백업
      backup_file = "db/backups/backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
      system("mkdir -p db/backups")
      system("pg_dump silmu_development > #{backup_file}")
      puts "💾 DB 백업 완료: #{backup_file}"

      # Git 커밋
      changes_summary = result[:changes].map { |c| "#{c[:topic]}/#{c[:field]}" }.uniq.join(", ")

      commit_message = <<~MSG
        fix: 법규정 자동 검증 및 수정

        수정 항목 (#{result[:changes].count}건):
        #{result[:changes].map { |c| "- [#{c[:topic]}] #{c[:wrong_value]} → #{c[:correct_value]}" }.join("\n")}

        근거: #{result[:changes].map { |c| c[:source] }.uniq.join(", ")}

        🤖 자동 검증 시스템에 의해 수정됨
        Co-Authored-By: Claude <noreply@anthropic.com>
      MSG

      system("git add -A")
      system("git commit -m '#{commit_message.gsub("'", "\\'")}'")
      system("git push")

      puts "✅ Git 푸시 완료!"
    end

    puts "\n🎉 검증 완료!"
  end

  desc "특정 토픽만 검증"
  task :topic, [ :slug ] => :environment do |_, args|
    unless args[:slug]
      puts "사용법: rails verify:topic[토픽슬러그]"
      puts "예시: rails verify:topic[travel-expense]"
      exit 1
    end

    topic = Topic.find_by(slug: args[:slug])
    unless topic
      puts "❌ 토픽을 찾을 수 없습니다: #{args[:slug]}"
      exit 1
    end

    verifier = RegulationVerifier.new
    verifier.verify_topic(topic)
  end

  desc "검증 리포트 목록 조회"
  task reports: :environment do
    report_dir = Rails.root.join("log", "regulation_reports")

    unless Dir.exist?(report_dir)
      puts "검증 리포트가 없습니다."
      exit
    end

    reports = Dir.glob(report_dir.join("*.json")).sort.reverse

    if reports.empty?
      puts "검증 리포트가 없습니다."
    else
      puts "📋 검증 리포트 목록:"
      reports.first(10).each do |report|
        data = JSON.parse(File.read(report))
        timestamp = data["timestamp"]
        changes = data.dig("summary", "total_changes") || 0
        errors = data.dig("summary", "total_errors") || 0
        puts "  #{File.basename(report)}: #{changes}건 수정, #{errors}건 오류"
      end
    end
  end
end
