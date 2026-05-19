# P6 ContentMigration Phase 1 — smoke test
#
# 데이터 변경 없음. 인프라 동작(파일 로드·이력 기록·멱등 skip)만 검증.
# Phase 2에서 실제 patch 시드(legal_basis_correction_*.rb 등) 컨버전 예정.

counts = {
  topics: Topic.count,
  audit_cases: AuditCase.count,
  guides: Guide.count,
  content_migrations: ContentMigration.count
}

puts "    [smoke] Topic=#{counts[:topics]} AuditCase=#{counts[:audit_cases]} Guide=#{counts[:guides]} ContentMigration=#{counts[:content_migrations]}"
