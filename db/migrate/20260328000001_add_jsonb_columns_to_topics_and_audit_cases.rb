class AddJsonbColumnsToTopicsAndAuditCases < ActiveRecord::Migration[8.1]
  def up
    return unless connection.adapter_name == "PostgreSQL"

    # topics: faqs text → jsonb (임시 컬럼 추가)
    add_column :topics, :faqs_data, :jsonb, default: []

    # audit_cases: checkpoints text → jsonb (임시 컬럼 추가)
    add_column :audit_cases, :checkpoints_data, :jsonb, default: []

    # 데이터 마이그레이션 (배치 처리, 앱 코드 미사용 → update_column 직접 사용)
    Topic.find_each do |t|
      next if t.faqs.blank? || t.faqs == "[]"

      begin
        parsed = JSON.parse(t.faqs)
        t.update_column(:faqs_data, parsed)
      rescue JSON::ParserError => e
        Rails.logger.warn "Topic #{t.id} faqs 파싱 실패: #{e.message}"
      end
    end

    AuditCase.find_each do |ac|
      next if ac.checkpoints.blank? || ac.checkpoints == "[]"

      begin
        parsed = JSON.parse(ac.checkpoints)
        ac.update_column(:checkpoints_data, parsed)
      rescue JSON::ParserError => e
        Rails.logger.warn "AuditCase #{ac.id} checkpoints 파싱 실패: #{e.message}"
      end
    end
  end

  def down
    remove_column :topics, :faqs_data
    remove_column :audit_cases, :checkpoints_data
  end
end
