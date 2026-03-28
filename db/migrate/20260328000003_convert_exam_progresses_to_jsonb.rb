class ConvertExamProgressesToJsonb < ActiveRecord::Migration[8.1]
  # exam_progresses의 text JSON 컬럼 6개를 jsonb로 변환 (2단계 전략)
  #
  # 대상 컬럼 (schema.rb 기준):
  #   bookmarks      text default: "[]"
  #   chapter_quizzes text default: "{}"
  #   chapters       text default: "{}"
  #   quizzes        text default: "{}"
  #   streak_history text default: "[]"
  #   wrong_answers  text default: "[]"
  #
  # ⚠️  ExamProgress 모델에 serialize :xxx, coder: JSON 가 선언돼 있으므로
  #     마이그레이션 B 실행 전 serialize 선언 제거 후 배포 필요.
  #     jsonb 컬럼은 Rails가 자동으로 Hash/Array로 반환하므로 serialize 불필요.

  # 컬럼별 default 값 (기존 text 기본값과 동일하게 유지)
  COLUMNS = [
    { name: :bookmarks,       default: [] },
    { name: :chapter_quizzes, default: {} },
    { name: :chapters,        default: {} },
    { name: :quizzes,         default: {} },
    { name: :streak_history,  default: [] },
    { name: :wrong_answers,   default: [] }
  ].freeze

  def up
    return unless connection.adapter_name == "PostgreSQL"

    # 1단계: 임시 jsonb 컬럼 추가
    COLUMNS.each do |col|
      add_column :exam_progresses, :"#{col[:name]}_jsonb", :jsonb, default: col[:default]
    end

    # 2단계: 데이터 복사 (text → jsonb)
    ExamProgress.find_each do |ep|
      updates = {}

      COLUMNS.each do |col|
        raw = ep.read_attribute(col[:name])
        next if raw.blank?

        begin
          # serialize :xxx, coder: JSON 로 인해 이미 Ruby 객체일 수 있음
          parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
          updates[:"#{col[:name]}_jsonb"] = parsed
        rescue JSON::ParserError => e
          Rails.logger.warn "ExamProgress #{ep.id} #{col[:name]} 파싱 실패: #{e.message}"
        end
      end

      ep.update_columns(updates) if updates.any?
    end
  end

  def down
    COLUMNS.each do |col|
      remove_column :exam_progresses, :"#{col[:name]}_jsonb"
    end
  end
end
