# 서울시교육청 공개문 기반 실제 사례 처분 정정 (2026-09-17 전수감사 G-13)
#
# ACTUAL 라벨 18건을 공개문 «제 목 → 조치할 사항» 단위로 대조한 결과 17건 일치, 1건 불일치.
# sen-2025-school-y-facility-multi-violation: 원문 «학교법인 예일학원 이사장은 이 건 관련자에게 “경고” 처분하시기 바랍니다»
# (「2025년 학교법인 Y학원 및 Y여고 종합감사 결과 공개문」 «시설공사관리 및 계약업무 집행 소홀» 조치할 사항) ↔ silmu «주의».

from = "## 처분\n학교법인 이사장 → 관련자 \"주의\" 처분.\n"
to = "## 처분\n학교법인 이사장 → 관련자 \"경고\" 처분.\n"

ActiveRecord::Base.transaction do
  record = AuditCase.find_by!(slug: "sen-2025-school-y-facility-multi-violation")
  detail = record.detail.to_s
  if detail.include?(to) && !detail.include?(from)
    puts "  [sen-disposition] changes=0"
  else
    raise "DISPOSITION_TEXT_NOT_FOUND" unless detail.include?(from)

    record.update_columns(detail: detail.sub(from, to), updated_at: Time.current)
    puts "  [sen-disposition] changes=1"
  end
end
