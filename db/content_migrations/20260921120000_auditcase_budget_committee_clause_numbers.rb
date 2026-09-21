# 감사사례 «학교운영위원회 심의 없이 예산 확정» — 초·중등교육법 제32조 제1항 호 번호 정정 (2026-09-21)
#
# 원문: 「초·중등교육법」 제32조제1항 (법제처 lsiSeq=283903, 2026.9.11. 시행)
#   1. 학교헌장과 학칙의 제정 또는 개정   2. 학교의 예산안과 결산   3. 학교교육과정의 운영방법
#   10. 학교급식   12. 학교운동부의 구성ㆍ운영
# 20260519230000 batch #2 가 legal_basis 만 제2호로 고치고 본문(detail 표·lesson)은 제1호로 남았다.
# 표의 나머지 3행(2·4·8호)도 원문과 달라, 예산 행만 고치면 «제2호» 가 두 번 나온다 → 호 번호만 함께 정정.
# 대상은 slug 1건. 각 old 는 해당 필드에 정확히 1회 있어야 하고, 하나라도 어긋나면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.
# 롤백: 같은 edits 의 new → old 역적용 (evidence BACKUP 의 detail·lesson 원문).

slug = "school-budget-without-committee-review"
edits = [
  [ "detail",
    "| 제1항 제1호 | 학교 예산안 및 결산 |\n| 제1항 제2호 | 학교 교육과정 운영 방법 |\n| 제1항 제4호 | 학교 급식 운영 방법 |\n| 제1항 제8호 | 학교 운동부 구성 및 운영 |",
    "| 제1항 제2호 | 학교 예산안 및 결산 |\n| 제1항 제3호 | 학교 교육과정 운영 방법 |\n| 제1항 제10호 | 학교 급식 운영 방법 |\n| 제1항 제12호 | 학교 운동부 구성 및 운영 |" ],
  [ "lesson",
    "초·중등교육법 제32조 제1항 제1호는 학교 예산안을",
    "초·중등교육법 제32조 제1항 제2호는 학교 예산안을" ]
]

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction do
  ac = AuditCase.find_by(slug: slug)
  if ac
    edits.each do |field, old, new|
      text = ac.public_send(field).to_s
      next if text.include?(new) && !text.include?(old)
      raise "[committee-clause] fingerprint missing: #{slug}.#{field}" unless text.scan(old).size == 1

      changes += 1
      ac.update_columns(field => text.sub(old) { new }, updated_at: Time.current) unless dry
    end
  end
end
puts "  [committee-clause] #{"DRY_RUN " if dry}changes=#{changes}"
