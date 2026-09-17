# 가상 예방 시나리오에서 실재 기관(감사원)을 적발 주체로 적은 서사 중립화 (2026-09-17 전수감사 G-13 TRUST REPAIR)
#
# 20260918090000 이 «가상 예방 시나리오»로 표시한 원문 없는 사례 중 5건이 «감사원 감사에서 적발/지적»이라고 적어
# 실재 기관의 실제 감사결과처럼 읽혔다(운영 덤프 + 선행 migration 적용 후 실측 8필드 9곳).
# 적발 주체만 «감사»로 바꾸고 교육 서사는 유지한다. 일반 경고(«감사원 특별감사 대상» 등)는 대상이 아니다.
# 가상 사례(SILMU_SIMULATED_CASE)만 바꾼다. DRY_RUN=1 이면 쓰지 않는다.

pattern = /감사원 (?:정기|특별|기관|합동)?\s*감사(?=에서|결과|를 통해|로)/
fields = %w[title issue detail action_taken lesson].freeze

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction do
  AuditCase.where(source_type: "SILMU_SIMULATED_CASE").find_each do |ac|
    updates = {}
    fields.each do |field|
      text = ac.public_send(field).to_s
      n = text.scan(pattern).size
      next if n.zero?

      updates[field] = text.gsub(pattern, "감사")
      changes += n
    end
    ac.update_columns(updates.merge(updated_at: Time.current)) if updates.any? && !dry
  end
end
puts "  [simulated-agency-attribution] #{"DRY_RUN " if dry}changes=#{changes}"
