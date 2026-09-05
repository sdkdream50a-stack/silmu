# frozen_string_literal: true

# P1 Authority Trust Layer — dry-run / backfill / 누출 스캔
#
# 안전 규칙 (§26·§27·§35)
#   · 실제 UPDATE 전에 반드시 dry-run CSV 를 만든다.
#   · 자동 적용은 HIGH confidence 만. MEDIUM 은 검토 큐, LOW 는 무변경.
#   · 운영 DB 직접 실행은 이 태스크의 책임이 아니다 — 명령과 영향범위를 문서로 남긴다.
namespace :silmu do
  namespace :p1 do
    DRY_RUN_DIR = Rails.root.join("tmp")

    desc "감사사례 provenance 분류 dry-run (CSV 생성, DB 변경 없음)"
    task provenance_dry_run: :environment do
      require "csv"
      path = DRY_RUN_DIR.join("silmu_p1_provenance_backfill.csv")
      FileUtils.mkdir_p(DRY_RUN_DIR)

      counts = Hash.new(0)
      CSV.open(path, "w", write_headers: true, headers: %w[
        content_id slug old_source proposed_source_type proposed_source_agency
        proposed_source_url proposed_verification_status confidence reason requires_review
      ]) do |csv|
        AuditCase.order(:id).find_each do |ac|
          plan = AuditCaseProvenanceClassifier.plan_for(ac)
          counts[plan.confidence] += 1
          counts["type:#{plan.source_type || '(무변경)'}"] += 1
          csv << [
            "audit_case:#{ac.id}", ac.slug, ac.verification_source,
            plan.source_type, plan.source_agency, plan.source_url,
            plan.verification_status, plan.confidence, plan.reason, plan.requires_review?
          ]
        end
      end

      puts "DRY-RUN → #{path}"
      counts.sort.each { |k, v| puts "  #{k}: #{v}" }
      puts "  (DB 변경 없음)"
    end

    desc "감사사례 provenance backfill 적용 (HIGH confidence 만)"
    task provenance_backfill: :environment do
      applied = skipped = 0
      AuditCase.order(:id).find_each do |ac|
        plan = AuditCaseProvenanceClassifier.plan_for(ac)
        unless plan.applicable?
          skipped += 1
          next
        end
        ac.update_columns(plan.attributes_to_apply.merge(updated_at: Time.current))
        applied += 1
      end
      puts "provenance backfill: applied=#{applied} skipped(non-HIGH)=#{skipped}"
    end

    desc "적용 기관 범위 dry-run (CSV 생성, DB 변경 없음)"
    task agency_dry_run: :environment do
      require "csv"
      path = DRY_RUN_DIR.join("silmu_p1_agency_scope.csv")
      FileUtils.mkdir_p(DRY_RUN_DIR)
      counts = Hash.new(0)

      CSV.open(path, "w", write_headers: true, headers: %w[
        content_id type slug proposed_target_agency proposed_jurisdiction confidence reason
      ]) do |csv|
        [ AuditCase, Topic, Guide ].each do |klass|
          klass.order(:id).find_each do |rec|
            plan = AgencyScopeClassifier.plan_for(rec)
            counts["#{klass.name}:#{plan.confidence}"] += 1
            csv << [
              "#{klass.name.underscore}:#{rec.id}", klass.name, rec.slug,
              Array(plan.target_agency).join("|"), plan.jurisdiction, plan.confidence, plan.reason
            ]
          end
        end
      end

      puts "DRY-RUN → #{path}"
      counts.sort.each { |k, v| puts "  #{k}: #{v}" }
      puts "  (DB 변경 없음)"
    end

    desc "적용 기관 범위 backfill (HIGH confidence 만)"
    task agency_backfill: :environment do
      [ AuditCase, Topic, Guide ].each do |klass|
        applied = skipped = 0
        klass.order(:id).find_each do |rec|
          plan = AgencyScopeClassifier.plan_for(rec)
          unless plan.applicable?
            skipped += 1
            next
          end
          rec.update_columns(plan.attributes_to_apply.merge(updated_at: Time.current))
          applied += 1
        end
        puts "#{klass.name} agency backfill: applied=#{applied} skipped=#{skipped}"
      end
    end

    desc "공개 렌더 경계 누출 스캔 (양성 대조 포함)"
    task leak_scan: :environment do
      # ⚠️ 이 스캔은 presenter 출력만 보면 **구조적으로 항상 0** 이 나온다(필터를 통과한 값이므로).
      #    그런 0 은 증거가 아니다. 그래서 세 가지를 함께 측정한다:
      #      ① 검출기 양성 대조 — 알려진 누출 문자열을 실제로 잡는가
      #      ② at_risk       — 경계가 없었다면 누출됐을 레코드 수 (경계의 실효 가치)
      #      ③ leaking       — 경계를 통과해 실제로 새는 레코드 수 (반드시 0)
      canary = "Phase A~E batch 01~03 (commits eed3ceb..12dff5d)"
      unless InternalMetadataFilter.internal?(canary) &&
             InternalMetadataFilter.public_only(canary).nil?
        abort("POSITIVE CONTROL 실패: 검출기가 알려진 누출 문자열을 잡지 못함 — 이 스캔의 0 은 무의미하다")
      end
      puts "positive control: OK (알려진 누출 문자열을 차단함)"

      total = at_risk = leaking = 0
      [ AuditCase, Topic, Guide ].each do |klass|
        klass.find_each do |rec|
          total += 1
          presenter = AuthorityPresenter.new(rec)

          # ② 경계가 없었다면 공개 후보로 쓰였을 원본 값들
          raw_candidates = [
            rec.try(:verification_source),
            rec.try(:source_agency),
            rec.try(:source_title),
            rec.try(:public_source_agency),
            rec.try(:public_source_title)
          ].compact
          at_risk += 1 if raw_candidates.any? { |v| InternalMetadataFilter.internal?(v) }

          # ③ presenter 를 통과한 실제 공개 값
          if InternalMetadataFilter.internal?(presenter.public_source_label)
            leaking += 1
            puts "  LEAK #{klass.name}##{rec.id} #{rec.slug}: #{presenter.public_source_label.to_s[0, 80]}"
          end
        end
      end

      puts "leak_scan: 검사 #{total}건 · 경계가 막아낸 at_risk #{at_risk}건 · 실제 누출 #{leaking}건"
      abort("공개 렌더 경계에서 내부 메타데이터 누출 발견") if leaking.positive?
    end
  end
end

# ── P1.5 §40 — 운영 backfill 사전점검 (production write 자동 실행 금지) ──
namespace :silmu do
  namespace :p1 do
    desc "운영 backfill 사전점검 — dry-run + 분류 + 위험 리포트. 쓰기 없음."
    task preflight: :environment do
      require "csv"
      env = Rails.env
      puts "=" * 72
      puts "P1 BACKFILL PREFLIGHT  env=#{env}  db=#{ActiveRecord::Base.connection_db_config.database}"
      puts "=" * 72

      total = AuditCase.count
      puts "\n[1] 대상 규모"
      puts "  audit_cases=#{total} · topics=#{Topic.count} · guides=#{Guide.count}"

      plans = AuditCase.order(:id).map { |ac| AuditCaseProvenanceClassifier.plan_for(ac) }
      by_conf = plans.group_by(&:confidence).transform_values(&:size)
      by_type = plans.group_by { |p| p.source_type || "(무변경)" }.transform_values(&:size)

      puts "\n[2] 분류 (dry-run)"
      puts "  confidence: #{by_conf}"
      puts "  source_type: #{by_type}"

      puts "\n[3] 이미 적용된 행 (재실행 안전성)"
      applied = AuditCase.where.not(source_type: nil).count
      puts "  source_type 채워진 행=#{applied} / #{total}"
      puts "  → 재실행해도 같은 값으로 덮어쓰므로 멱등이다"

      puts "\n[4] 위험 점검"
      risks = []
      bad = plans.count { |p| p.source_type == "ACTUAL_AUDIT" && p.source_url.blank? }
      risks << "ACTUAL_AUDIT 인데 원문 URL 없음: #{bad}건 (0이어야 함)" if bad.positive?
      med = plans.count(&:requires_review?)
      puts "  ACTUAL_AUDIT + 원문 URL 결손: #{bad}건 #{bad.zero? ? '✅' : '🔴'}"
      puts "  MEDIUM (자동 적용 안 됨, 사람 검토 대상): #{med}건"
      leak = AuditCase.count { |ac| InternalMetadataFilter.internal?(AuthorityPresenter.new(ac).public_source_label) }
      puts "  공개 렌더 경계 누출: #{leak}건 #{leak.zero? ? '✅' : '🔴'}"
      risks << "공개 누출 #{leak}건" if leak.positive?

      puts "\n[5] 실행 명령 (승인 후 수동 실행)"
      puts "  RAILS_ENV=production bin/rails silmu:p1:provenance_dry_run   # CSV 확인"
      puts "  RAILS_ENV=production bin/rails silmu:p1:provenance_backfill  # HIGH 만 적용"
      puts "  RAILS_ENV=production bin/rails silmu:p1:agency_backfill"
      puts "  RAILS_ENV=production bin/rails silmu:p1:leak_scan"

      puts "\n[6] 판정"
      if risks.empty?
        puts "  PREFLIGHT_OK — 위 명령을 명시적 승인 후 실행할 수 있다"
      else
        puts "  PREFLIGHT_BLOCKED"
        risks.each { |r| puts "    · #{r}" }
      end
      puts "\n  ⚠️ 이 태스크는 아무것도 쓰지 않았다 (ACTUAL_WRITE=0)"
      puts "=" * 72
    end
  end
end
