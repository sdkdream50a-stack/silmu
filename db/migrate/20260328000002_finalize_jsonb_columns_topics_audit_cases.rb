class FinalizeJsonbColumnsTopicsAuditCases < ActiveRecord::Migration[8.1]
  # ⚠️  실행 전 체크리스트:
  #   1. 마이그레이션 A(20260328000001) 배포 후 코드가 faqs_data / checkpoints_data를 읽도록 전환됐는지 확인
  #   2. topics.faqs_data, audit_cases.checkpoints_data 데이터 정합성 검증 완료
  #   3. 구 컬럼(faqs, checkpoints) 참조 코드가 완전히 제거됐는지 확인

  def up
    return unless connection.adapter_name == "PostgreSQL"

    # topics: 구 text 컬럼 삭제 → 새 jsonb 컬럼 rename
    remove_column :topics, :faqs
    rename_column :topics, :faqs_data, :faqs

    # audit_cases: 구 text 컬럼 삭제 → 새 jsonb 컬럼 rename
    remove_column :audit_cases, :checkpoints
    rename_column :audit_cases, :checkpoints_data, :checkpoints

    # JSONB GIN 인덱스 추가 (빈 배열 제외)
    add_index :topics, :faqs,
              using: :gin,
              where: "faqs != '[]'::jsonb",
              name: "index_topics_on_faqs_jsonb"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "구 text 컬럼(faqs, checkpoints) 데이터가 이미 삭제됐으므로 롤백 불가. " \
          "필요 시 마이그레이션 A(20260328000001)만 롤백하고 수동 복구할 것."
  end
end
