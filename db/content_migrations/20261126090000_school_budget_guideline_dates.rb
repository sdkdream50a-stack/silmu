# 학교회계 예산편성 토픽(school-budget-compilation) — 지침 시달 «9월/10월» 고정 월 제거
#
# 무엇을 고치나 (기준일 2026-11-26)
#   · 도입부 «전년도 10월 지침 시달», 흐름도·주요 일정 «9월 지침 통보 / 10~11월 예산안 작성»
#     → 전국 공통 근거가 없는 고정 월. 지침 수령 → 변경 내용 확인 → 학교 예산안 편성 순서로 바꾸고
#       실제 시달일은 소속 교육청 공문으로 확인하도록 안내.
#   · 예산안 제출(30일 전)·심의(5일 전) 등 다른 기한 문구는 그대로.
#
# 근거
#   시·도 교육규칙(학교회계 규칙) — 17개 교육청 «회계연도 개시 3개월 전까지» 지침 시달
#   (예: 경상남도 공립학교회계 규칙 제10조, 2026-11-26 국가법령정보센터 대조)
#   초·중등교육법 제30조의3 ②③
#
# 안전장치 — 바꿀 필드마다 2026-11-26 운영값 SHA256 앞 16자리 고정. 다르면 아무것도 쓰지 않고 실패.
#   이미 새 값이면 건너뜀(멱등). DRY_RUN=1 이면 출력만.
require "digest"

module SchoolBudgetGuidelineCorrection20261126
  SLUG = "school-budget-compilation"
  DATA_DIR = Rails.root.join("db/content_migrations/data/20261126_school_budget_guideline")
  GUARDS = {
    "summary" => "747fb60adc19ef08",
    "practical_tips" => "5a275f2a9e8f9c2c",
    "flowchart_mermaid" => "3216487dc42b6dcf"
  }.freeze

  module_function

  def value(field) = File.read(DATA_DIR.join("#{field}.md"), encoding: "UTF-8")

  def fingerprint(text) = Digest::SHA256.hexdigest(text.to_s)[0, 16]

  def plan
    topic = Topic.find_by!(slug: SLUG)
    changes = {}
    mismatches = []
    GUARDS.each do |field, guard|
      current = topic[field].to_s
      new_value = value(field)
      next if current == new_value

      if fingerprint(current) == guard
        changes[field] = new_value
      else
        mismatches << "#{field} (운영값 #{fingerprint(current)} ≠ 기대 #{guard})"
      end
    end
    [ topic, changes, mismatches ]
  end

  def run!(dry_run: ENV["DRY_RUN"].present?)
    topic, changes, mismatches = plan
    raise "운영값이 검증 시점과 달라 중단 — 아무것도 쓰지 않음: #{mismatches.join(', ')}" if mismatches.any?

    puts "[#{dry_run ? 'dry-run' : 'apply'}] #{SLUG}: #{changes.keys.join(', ').presence || '변경 없음(이미 반영)'}"
    topic.update!(changes) if !dry_run && changes.any?
    changes
  end
end

SchoolBudgetGuidelineCorrection20261126.run! unless defined?(SCHOOL_BUDGET_GUIDELINE_CORRECTION_LIBRARY_ONLY)
