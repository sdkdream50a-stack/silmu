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
#   bin/rake silmu:content_cache_invalidate  # 콘텐츠 파생 캐시 무효화 (G-57)
#
# ⚠️ content_migrate 는 적용이 1건 이상이면 끝에 ContentCache.invalidate! 를 **자동** 호출한다.
#    migration 이 update_columns 로 쓰기 때문에 모델 after_commit 무효화 콜백이 돌지 않는다(G-57).
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

    # G-57 (2026-09-18) — 여기가 빠져 있었다.
    #
    #   content migration 은 `update_columns` 로 쓰므로 after_commit 무효화 콜백이 실행되지 않는다.
    #   그래서 DB 는 새 값인데 Rails origin 이 최대 1시간 옛 값을 서빙했고, 복구를 운영 콘솔에서
    #   캐시 키 784개를 손으로 지워서 했다. 그 수동 절차를 여기로 끌어들인다.
    #
    #   적용이 0건이면 부르지 않는다 — 아무것도 안 바뀌었는데 캐시를 비우면 불필요한 부하다.
    if applied_count.positive?
      report = ContentCache.invalidate!
      puts "  [cache] 무효화 #{report}"
      # 「지웠다」고 말했는데 0건이면 무효화가 동작하지 않은 것이다 — 조용히 넘기지 않는다.
      warn "  [WARN] 캐시 무효화가 아무것도 지우지 못했다 — ContentCache 등록부를 확인하라" unless report.any?
    end

    puts ""
    puts "[INFO] ContentMigration 완료 — applied=#{applied_count} skipped=#{skipped_count} failed=#{failed_count}"
    exit(failed_count.zero? ? 0 : 1)
  end

  desc "G-57 — 콘텐츠 파생 캐시 무효화 (배포 절차·수동 복구용)"
  task content_cache_invalidate: :environment do
    report = ContentCache.invalidate!
    puts "[INFO] ContentCache 무효화 — #{report}"
    abort "[FAIL] 아무것도 지우지 못했다 — 캐시 스토어·등록부를 확인하라" unless report.any?
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
