# P3 Sprint 2 — 공통표준용어 sample 콘텐츠 준수율 측정 (정보성)
#
# 운영 DB의 Topic·AuditCase 표준 텍스트 컬럼에 StandardTermCorrector.call 적용 →
# 누적 어절 수 대비 변경 수로 전체 준수율 출력.
#
# 정보성 task: FAIL 미발생, exit 0만 반환. legal_lint와 분리해 환경 로드 비용을
# 빠른 lint 워크플로에 부담시키지 않음.
#
# 사용: bin/rake silmu:term_compliance
#       bin/rake silmu:legal_lint silmu:term_compliance  # 두 게이트 함께
#
# 메모: synonym_index가 비어 있으면 (CSV 13K건 미적재 / DB 빈 환경) skip.
namespace :silmu do
  desc "P3 Sprint 2 — Topic·AuditCase sample 표준어 준수율 측정 (정보성)"
  task term_compliance: :environment do
    unless defined?(StandardTerm) && StandardTerm.table_exists?
      puts "[SKIP] standard_terms 테이블 없음 (마이그레이션 미실행)"
      exit 0
    end

    synonym_count = StandardTerm.count
    if synonym_count.zero?
      puts "[SKIP] standard_terms 적재 0건 — bin/rails db:seed 또는 CSV 적재 필요"
      exit 0
    end

    sample_limit = (ENV["SAMPLE_LIMIT"] || 50).to_i
    topic_fields      = %i[summary commentary practical_tips law_content decree_content rule_content]
    audit_case_fields = %i[issue detail lesson action_taken]

    total_words = 0
    total_changes = 0
    worst = []

    Topic.published.order(view_count: :desc).limit(sample_limit).find_each do |topic|
      topic_fields.each do |field|
        text = topic.public_send(field).to_s
        next if text.blank?
        result = StandardTermCorrector.call(text)
        words = text.scan(/\S+/).size
        total_words += words
        total_changes += result[:changes].size
        if result[:changes].any?
          worst << { kind: "Topic", slug: topic.slug, field: field,
                     rate: result[:compliance_rate], count: result[:changes].size }
        end
      end
    end

    AuditCase.published.order(created_at: :desc).limit(sample_limit).find_each do |ac|
      audit_case_fields.each do |field|
        text = ac.public_send(field).to_s
        next if text.blank?
        result = StandardTermCorrector.call(text)
        words = text.scan(/\S+/).size
        total_words += words
        total_changes += result[:changes].size
        if result[:changes].any?
          worst << { kind: "AuditCase", slug: ac.slug, field: field,
                     rate: result[:compliance_rate], count: result[:changes].size }
        end
      end
    end

    overall = total_words.zero? ? 1.0 : (1.0 - total_changes.to_f / total_words).clamp(0.0, 1.0).round(4)
    pct = (overall * 100).round(2)

    topic_total = Topic.published.limit(sample_limit).count
    ac_total    = AuditCase.published.limit(sample_limit).count

    puts "[INFO] 공통표준용어 sample 준수율 — #{pct}%"
    puts "  - 적재 표준어: #{synonym_count}건 (sample 50건 한도면 노출 효과 제한적)"
    puts "  - 검사 대상: Topic #{topic_total}건 + AuditCase #{ac_total}건 (sample_limit=#{sample_limit})"
    puts "  - 누적 어절: #{total_words}건 / 변경 후보: #{total_changes}건"

    if worst.any?
      puts ""
      puts "  교정 빈도 상위 10건:"
      worst.sort_by { |w| -w[:count] }.first(10).each do |w|
        puts "    - #{w[:kind]} #{w[:slug]} (#{w[:field]}): #{w[:count]}건 (필드 준수율 #{(w[:rate] * 100).round(1)}%)"
      end
    end

    puts ""
    puts "  📌 본 게이트는 정보성. FAIL 미발생. CSV 13,176건 적재 후 의미 있는 수치 노출 예정."
    exit 0
  end
end
