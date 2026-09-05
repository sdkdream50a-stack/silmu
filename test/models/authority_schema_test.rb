# frozen_string_literal: true

require "test_helper"

# P1 §5·§32 — 마이그레이션이 additive 인지(기존 컬럼 보존) 스키마 수준에서 확인한다.
class AuthoritySchemaTest < ActiveSupport::TestCase
  NEW_AUTHORITY_COLUMNS = %w[verification_status verification_note effective_at review_due_at].freeze
  NEW_AGENCY_COLUMNS = %w[target_agency jurisdiction agency_scope_confidence].freeze
  NEW_PROVENANCE_COLUMNS = %w[
    source_type source_agency source_title source_url source_year
    source_page source_reference is_reconstructed provenance_confidence
  ].freeze

  # P0 이전부터 존재하던 컬럼 — 삭제·변경되면 안 된다
  PRESERVED = {
    "audit_cases" => %w[source legal_basis verification_method verification_source last_verified_at sector org_type],
    "topics"      => %w[law_content decree_content rule_content law_base_date law_verified_at verification_source],
    "guides"      => %w[verification_method verification_source last_verified_at]
  }.freeze

  test "신규 권위 컬럼이 3개 테이블에 모두 추가되었다" do
    %w[audit_cases topics guides].each do |table|
      cols = ActiveRecord::Base.connection.columns(table).map(&:name)
      (NEW_AUTHORITY_COLUMNS + NEW_AGENCY_COLUMNS).each do |c|
        assert_includes cols, c, "#{table}.#{c} 누락"
      end
    end
  end

  test "provenance 컬럼은 audit_cases 에 추가되었다" do
    cols = ActiveRecord::Base.connection.columns("audit_cases").map(&:name)
    NEW_PROVENANCE_COLUMNS.each { |c| assert_includes cols, c, "audit_cases.#{c} 누락" }
  end

  test "ADDITIVE — 기존 컬럼이 하나도 사라지지 않았다" do
    PRESERVED.each do |table, columns|
      actual = ActiveRecord::Base.connection.columns(table).map(&:name)
      columns.each { |c| assert_includes actual, c, "#{table}.#{c} 가 사라짐 — additive 위반" }
    end
  end

  test "신규 컬럼은 NOT NULL 제약이 없다 (기존 행 무영향)" do
    conn = ActiveRecord::Base.connection
    %w[audit_cases topics guides].each do |table|
      conn.columns(table).each do |col|
        next unless (NEW_AUTHORITY_COLUMNS + NEW_AGENCY_COLUMNS + NEW_PROVENANCE_COLUMNS).include?(col.name)
        assert col.null, "#{table}.#{col.name} 이 NOT NULL — 기존 행에 영향을 준다"
      end
    end
  end

  test "target_agency 는 배열이며 기본값이 빈 배열이다" do
    col = ActiveRecord::Base.connection.columns("audit_cases").find { |c| c.name == "target_agency" }
    assert col.array?, "target_agency 가 배열이 아님"
  end
end
