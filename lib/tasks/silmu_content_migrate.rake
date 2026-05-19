# P6 ContentMigration Phase 1 — db/content_migrations/*.rb 순차 실행 + 추적
#
# 동작:
#   - db/content_migrations/ 디렉토리의 .rb 파일을 파일명 정렬해 순차 로드
#   - ContentMigration 레코드로 적용 이력 추적 (filename unique)
#   - 이미 applied 상태면 skip (멱등성)
#   - 실패 시 status="failed" + error_message 기록, 다음 파일 계속 진행
#
# 사용:
#   bin/rake silmu:content_migrate           # 적용 안 된 파일 실행
#   bin/rake silmu:content_migrate:status    # 현재 적용 이력 출력
#   bin/rake silmu:content_migrate:retry     # failed 상태 재시도
namespace :silmu do
  desc "P6 — db/content_migrations/*.rb 순차 적용 (멱등, 운영 DB 거버넌스)"
  task content_migrate: :environment do
    dir = Rails.root.join("db/content_migrations")
    files = Dir[dir.join("*.rb")].sort
    if files.empty?
      puts "[INFO] db/content_migrations/ 에 적용할 파일 없음"
      exit 0
    end

    applied_count = 0
    skipped_count = 0
    failed_count  = 0

    files.each do |path|
      filename = File.basename(path)
      record = ContentMigration.find_or_initialize_by(filename: filename)

      if record.persisted? && record.status == "applied"
        skipped_count += 1
        next
      end

      started_at = Time.current
      begin
        load(path)
        elapsed = ((Time.current - started_at) * 1000).to_i
        record.update!(
          status: "applied",
          applied_at: Time.current,
          duration_ms: elapsed,
          error_message: nil
        )
        puts "  [applied] #{filename} (#{elapsed}ms)"
        applied_count += 1
      rescue => e
        record.update!(
          status: "failed",
          applied_at: nil,
          duration_ms: nil,
          error_message: "#{e.class}: #{e.message}"
        )
        puts "  [failed]  #{filename}: #{e.class} #{e.message}"
        failed_count += 1
      end
    end

    puts ""
    puts "[INFO] ContentMigration 완료 — applied=#{applied_count} skipped=#{skipped_count} failed=#{failed_count}"
    exit(failed_count.zero? ? 0 : 1)
  end

  namespace :content_migrate do
    desc "현재 ContentMigration 적용 이력 출력"
    task status: :environment do
      puts "[ContentMigration 적용 이력]"
      ContentMigration.order(:filename).each do |m|
        applied = m.applied_at&.strftime("%Y-%m-%d %H:%M") || "-"
        puts "  #{m.status.ljust(8)} #{applied.ljust(20)} #{m.filename}"
        puts "    error: #{m.error_message}" if m.error_message.present?
      end
      puts "  (총 #{ContentMigration.count}건: applied=#{ContentMigration.applied.count} pending=#{ContentMigration.pending.count} failed=#{ContentMigration.failed.count})"
    end

    desc "failed 상태 ContentMigration 재시도"
    task retry: :environment do
      ContentMigration.failed.update_all(status: "pending")
      Rake::Task["silmu:content_migrate"].invoke
    end
  end
end
