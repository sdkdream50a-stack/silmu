# frozen_string_literal: true

# P1 §23 Agency Scope Foundation — 적용 기관 범위를 표현할 수 있는 기반.
#
# P0 실측: target_agency 를 판별할 수 없는 콘텐츠가 549건 중 352건(64%).
# 이번 단계는 **스키마와 UI 기반만** 만들고 HIGH confidence backfill 만 허용한다.
# 부정확한 metadata 는 빈 metadata 보다 위험하므로 애매하면 비워 둔다.
#
# ADDITIVE ONLY / NON-DESTRUCTIVE / REVERSIBLE
# target_agency 는 default [] 를 갖는다 — PG 11+ 에서 기본값 있는 컬럼 추가는 즉시 완료된다.
class AddAgencyScopeToContents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %i[topics guides audit_cases].freeze

  def change
    TABLES.each do |table|
      add_column table, :target_agency, :string, array: true, default: []
      add_column table, :jurisdiction, :string
      add_column table, :agency_scope_confidence, :string

      add_index table, :jurisdiction, algorithm: :concurrently
      add_index table, :target_agency, using: :gin, algorithm: :concurrently
    end
  end
end
