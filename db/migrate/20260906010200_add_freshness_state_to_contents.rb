# frozen_string_literal: true

# P1.5 §11 — 콘텐츠 freshness 상태를 boolean 이 아니라 상태로 저장한다.
#
# P1 은 `review_due_at` 에서 상태를 **유도**했다(CURRENT/REVIEW_DUE/STALE_SUSPECTED/UNKNOWN).
# 여기서는 엔진이 **관측한 사실**(변경 감지·검토 필요·검증 완료·출처 장애)을 저장할 자리를 만든다.
# 유도값은 그대로 남고, 저장값이 있으면 그것이 우선한다.
#
# ADDITIVE ONLY / NON-DESTRUCTIVE / REVERSIBLE
class AddFreshnessStateToContents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %i[topics guides audit_cases].freeze

  def change
    TABLES.each do |table|
      add_column table, :freshness_state, :string
      add_column table, :freshness_state_at, :datetime
      add_column table, :last_change_event_id, :bigint

      add_index table, :freshness_state, algorithm: :concurrently
    end
  end
end
