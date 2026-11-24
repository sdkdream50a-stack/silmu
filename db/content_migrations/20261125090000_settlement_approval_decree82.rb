# 결산 승인 시기 정정 — budget-settlement 토픽 · 감사사례 settlement-report-delayed
#
# 무엇을 고치나 (기준일 2026-11-25, 국가법령정보센터 원문 대조)
#   · "승인은 다음 해", "승인 날짜는 법에 없음"
#       → 지방의회 제1차 정례회의 회기 내 승인(지방자치법 시행령 제82조)
#   · 세 기한 구분: 출납 폐쇄 후 80일 이내 작성 / 다음 연도 5월 31일까지 제출 / 제1차 정례회 회기 내 승인
#   · 교육비특별회계: 지방교육자치법 제3조로 지방자치법 제150조·시행령 제82조 준용(시·도의회)
#     학교회계(학교운영위원회 2개월 이내 제출, 초·중등교육법 제30조의3)는 그대로 별도 표기
#
# 근거 조문
#   지방자치법 시행령 제82조(결산 승인) [시행 2026.7.1.]
#     "법 제150조에 따른 지방의회의 결산 승인은 제1차 정례회의의 회기 내에 처리해야 한다."
#   지방자치법 제150조 [시행 2026.10.15.] / 지방회계법 시행령 제10조 [시행 2026.6.2.]
#   지방교육자치에 관한 법률 제3조 [시행 2026.5.12.]
#
# 안전장치 (20261124 정정과 같은 방식)
#   · 바꿀 필드마다 2026-11-24 정정 후 운영값의 SHA256 앞 16자리를 고정. 다르면 아무것도 쓰지 않고 실패.
#   · 이미 새 값이면 건너뜀(멱등). 한 트랜잭션. DRY_RUN=1 이면 출력만.
#   · 새 본문은 data/20261124_mas_settlement/<dir>/<field> — 시드와 같은 파일.
require "digest"

module SettlementApprovalCorrection20261125
  DATA_DIR = Rails.root.join("db/content_migrations/data/20261124_mas_settlement")

  TOPIC_GUARDS = {
    "budget-settlement" => {
      "decree_content" => "c2eb4b36ec4cc7d3",
      "faqs" => "a38680e6b6ddf4f9",
      "interpretation_content" => "fd56ec03bf71f51b",
      "law_content" => "d35d165e7f20dfc6",
      "qa_content" => "5dd3e003bc47d75d",
      "quick_stats" => "a3677dc4505c67e1",
      "regulation_content" => "317cd36c862713c5",
      "rule_content" => "7d3ec4c728acb9a3",
      "summary" => "dc6d77feb4fab6bb"
    }
  }.freeze

  AUDIT_GUARDS = {
    "settlement-report-delayed" => {
      "detail" => "06feaf9f15f0a7cf",
      "legal_basis" => "d294fc774e72f8fd",
      "lesson" => "3cd31efd2d381516"
    }
  }.freeze

  module_function

  def value(dir, field)
    path = Dir[DATA_DIR.join(dir, "#{field}.{md,json}")].first or raise "#{dir}/#{field} 데이터 파일 없음"
    raw = File.read(path, encoding: "UTF-8")
    path.end_with?(".json") ? JSON.parse(raw) : raw
  end

  def canonical(value)
    return value.to_s unless value.is_a?(Array) || value.is_a?(Hash)

    JSON.generate(value.is_a?(Array) ? value.map { |h| h.is_a?(Hash) ? h.sort.to_h : h } : value.sort.to_h)
  end

  def fingerprint(value)
    Digest::SHA256.hexdigest(canonical(value))[0, 16]
  end

  def plan
    mismatches = []
    targets = TOPIC_GUARDS.map { |slug, g| [ Topic.find_by!(slug: slug), slug, g ] } +
              AUDIT_GUARDS.map { |slug, g| [ AuditCase.find_by!(slug: slug), "audit-#{slug}", g ] }
    plans = targets.map do |record, dir, guards|
      changes = {}
      guards.each do |field, guard|
        current = record.public_send(field)
        new_value = value(dir, field)
        next if canonical(current) == canonical(new_value)

        if fingerprint(current) == guard
          changes[field] = new_value
        else
          mismatches << "#{dir}.#{field} (운영값 #{fingerprint(current)} ≠ 기대 #{guard})"
        end
      end
      { record: record, label: dir, changes: changes }
    end
    [ plans, mismatches ]
  end

  def run!(dry_run: ENV["DRY_RUN"].present?)
    plans, mismatches = plan
    raise "운영값이 검증 시점과 달라 중단 — 아무것도 쓰지 않음: #{mismatches.join(', ')}" if mismatches.any?

    plans.each do |p|
      puts "[#{dry_run ? 'dry-run' : 'apply'}] #{p[:label]}: #{p[:changes].keys.join(', ').presence || '변경 없음(이미 반영)'}"
    end
    return plans if dry_run

    Topic.transaction do
      plans.each { |p| p[:record].update!(p[:changes]) if p[:changes].any? }
    end
    plans
  end
end

SettlementApprovalCorrection20261125.run! unless defined?(SETTLEMENT_APPROVAL_CORRECTION_LIBRARY_ONLY)
