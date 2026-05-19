class AddVerificationFieldsToContentModels < ActiveRecord::Migration[8.1]
  # 2026-05-19 권위자 P7(법무) + P4(SEO) 권고 #C — 콘텐츠 검증 추적성
  # last_verified_at: 마지막 법령 정합성 검증 시각
  # verification_method: "mcp_law_api"(법제처 OPEN API) / "manual"(수동) / "pdf"(PDF 대조) 등
  # verification_source: 구체 출처 (예: "lawId 012559 MST 276363", "법제처 mcp batch #4")
  #
  # 모두 nullable → 기존 row 영향 없음 (Strong Migrations 안전 패턴, add_column 직접 사용)
  # 인덱스는 차후 별도 마이그레이션에서 add_index algorithm: :concurrently로 추가
  # (현재 query 빈도 낮음 — view에서 단일 record 조회 위주)
  def change
    add_column :topics, :last_verified_at, :datetime
    add_column :topics, :verification_method, :string, limit: 32
    add_column :topics, :verification_source, :string, limit: 200

    add_column :guides, :last_verified_at, :datetime
    add_column :guides, :verification_method, :string, limit: 32
    add_column :guides, :verification_source, :string, limit: 200

    add_column :audit_cases, :last_verified_at, :datetime
    add_column :audit_cases, :verification_method, :string, limit: 32
    add_column :audit_cases, :verification_source, :string, limit: 200
  end
end
