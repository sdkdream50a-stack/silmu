# frozen_string_literal: true

# P1-1 Provenance Model — 감사사례 출처 유형을 구조화한다.
#
# 배경(P0 감사): 감사사례의 출처가 `verification_source` 자유 문자열 하나에 뭉쳐 있어
#   ① 내부 엔지니어링 로그(커밋 해시·batch·lawId)가 공개 화면에 노출되고
#   ② 재구성 사례와 실제 감사 지적을 사용자가 구분할 수 없었다.
# 기존 `source` jsonb 에는 이미 원문 URL·페이지·발행기관이 들어 있으나 렌더되지 않았다.
#
# ADDITIVE ONLY / NON-DESTRUCTIVE / REVERSIBLE — 기존 컬럼은 삭제·변경하지 않는다.
# 모든 신규 컬럼은 nullable, 기본값 없음 → 기존 행/쿼리에 영향 없음.
class AddProvenanceToAuditCases < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :audit_cases, :source_type, :string
    add_column :audit_cases, :source_agency, :string
    add_column :audit_cases, :source_title, :string
    add_column :audit_cases, :source_url, :string
    add_column :audit_cases, :source_year, :integer
    add_column :audit_cases, :source_page, :integer
    add_column :audit_cases, :source_reference, :string
    # nullable boolean: null = 미판정 (false 와 의미가 다르다)
    add_column :audit_cases, :is_reconstructed, :boolean
    add_column :audit_cases, :provenance_confidence, :string

    add_index :audit_cases, :source_type, algorithm: :concurrently
    add_index :audit_cases, :is_reconstructed, algorithm: :concurrently
  end
end
