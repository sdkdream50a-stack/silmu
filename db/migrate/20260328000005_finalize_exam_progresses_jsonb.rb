class FinalizeExamProgressesJsonb < ActiveRecord::Migration[8.1]
  # ⚠️  실행 전 체크리스트:
  #   1. 마이그레이션 3(20260328000003) 배포 후 앱이 *_jsonb 컬럼을 사용하도록 전환됐는지 확인
  #   2. ExamProgress 모델에서 `serialize :xxx, coder: JSON` 선언 제거 완료
  #   3. *_jsonb 컬럼 데이터 정합성 검증 완료
  #   4. 구 text 컬럼 참조 코드가 완전히 제거됐는지 확인

  COLUMNS = %i[bookmarks chapter_quizzes chapters quizzes streak_history wrong_answers].freeze

  def up
    return unless connection.adapter_name == "PostgreSQL"

    COLUMNS.each do |col|
      remove_column :exam_progresses, col
      rename_column :exam_progresses, :"#{col}_jsonb", col
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "구 text 컬럼 데이터가 이미 삭제됐으므로 롤백 불가. 수동 복구 필요."
  end
end
