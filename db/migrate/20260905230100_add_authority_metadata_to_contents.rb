# frozen_string_literal: true

# P1-1 / P1-6 — 검증 의미 분리 + 신선도(freshness) 기반.
#
# 핵심 설계 원칙(P1 §7): 하나의 boolean `verified=true` 로 모든 검증을 표현하지 않는다.
#   CONTENT_CONSISTENCY_VERIFIED / LEGAL_REFERENCE_VERIFIED / OFFICIAL_SOURCE_VERIFIED
#   / RECONSTRUCTED / UNVERIFIED 를 구분한다.
#
# `verification_note` 는 INTERNAL 전용이다 — 기존 `verification_source` 의 내부 문자열
# (batch·commit·lawId 등)을 무손실 이관받고, 공개 렌더러는 이 컬럼을 절대 읽지 않는다.
#
# ADDITIVE ONLY / NON-DESTRUCTIVE / REVERSIBLE
class AddAuthorityMetadataToContents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %i[topics guides audit_cases].freeze

  def change
    TABLES.each do |table|
      add_column table, :verification_status, :string
      add_column table, :verification_note, :text   # INTERNAL ONLY — 공개 렌더 금지
      add_column table, :effective_at, :date
      add_column table, :review_due_at, :date

      add_index table, :verification_status, algorithm: :concurrently
      add_index table, :review_due_at, algorithm: :concurrently
    end
  end
end
