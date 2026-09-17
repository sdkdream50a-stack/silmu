# 감사사례 징계 분류 오류 정정 — «감봉·견책 = 중징계» (2026-09-17 전수감사 G-13 TRUST REPAIR)
#
# 원문: 「공무원 징계령」 제1조의3(2026.6.30. 시행) · 「지방공무원 징계 및 소청 규정」 제1조의3 —
#   “중징계”란 파면·해임·강등 또는 정직, “경징계”란 감봉 또는 견책.
# 운영 덤프(2026-09-17 19:45) 감사사례 21필드(20건)가 감봉·견책을 «중징계»로 표기.
# 함께: performance-guarantee-waiver-loss «징계부가금 (감면액의 1/4)» 삭제 — 「지방공무원법」 제69조의2①은
#   금품 취득·제공 또는 예산·기금 등의 횡령·배임·절도·사기·유용에 한해 «5배 내» 부과이고, 보증금 면제 손실은 그 요건이 아니며 «1/4» 기준은 없다.
# 각 old 는 해당 필드에 정확히 1회 있어야 하고, 하나라도 어긋나면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.

edits = [
  [ "budget-unauthorized-transfer", "action_taken", "관련자 중징계(감봉)", "관련자 경징계(감봉)" ],
  [ "budget-unauthorized-transfer", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "budget-transfer-limit-violation", "detail", "감봉 1개월 (중징계)", "감봉 1개월 (경징계)" ],
  [ "contract-verbal-agreement", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "private-contract-retroactive", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "performance-guarantee-waiver-loss", "detail", "감봉 3개월 (중징계)\n- 징계부가금 부과 (감면액 4,000만원의 1/4, 1,000만원)", "감봉 3개월 (경징계)" ],
  [ "private-contract-split", "action_taken", "관련자 중징계(감봉)", "관련자 경징계(감봉)" ],
  [ "private-contract-split", "lesson", "담당자는 감봉 이상의 중징계를 받으며", "담당자는 사안에 따라 징계(견책·감봉 등 경징계 또는 정직 이상 중징계)를 받을 수 있으며" ],
  [ "budget-misuse", "detail", "감봉 1개월 (중징계)", "감봉 1개월 (경징계)" ],
  [ "school-budget-without-committee-review", "detail", "**견책** 처분 (법령 위반으로 중징계 경계)", "**견책** 처분 (경징계)" ],
  [ "public-procurement-mandatory-bid-bypassed", "detail", "감봉 3개월 (중징계)", "감봉 3개월 (경징계)" ],
  [ "private-contract-split-over-limit", "detail", "감봉 2개월 (중징계)", "감봉 2개월 (경징계)" ],
  [ "business-expense-personal-use", "detail", "**감봉 3개월** (중징계)", "**감봉 3개월** (경징계)" ],
  [ "emergency-contract-unjustified", "detail", "감봉 1개월 (중징계)", "감봉 1개월 (경징계)" ],
  [ "contract-wrong-party", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "progress-payment-over-claimed", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "payment-before-inspection", "detail", "감봉 1개월 (중징계)", "감봉 1개월 (경징계)" ],
  [ "contract-guarantee-not-collected", "detail", "감봉 3개월 (중징계)", "감봉 3개월 (경징계)" ],
  [ "expenditure-over-budget", "detail", "**감봉 1개월** (중징계)", "**감봉 1개월** (경징계)" ],
  [ "payment-without-completion", "detail", "감봉 처분(중징계)", "감봉 처분(경징계)" ],
  [ "performance-bonus-score-manipulation", "lesson", "징계(감봉, 정직 등 중징계 가능)", "징계(감봉 등 경징계 또는 정직 이상 중징계 가능)" ]
]

dry = ENV["DRY_RUN"] == "1"
changes = 0
missing = []
ActiveRecord::Base.transaction do
  edits.group_by { |slug, field, _, _| [ slug, field ] }.each do |(slug, field), list|
    ac = AuditCase.find_by(slug: slug)
    next missing << slug unless ac

    text = ac.public_send(field).to_s
    list.each do |_, _, old, new|
      next if text.include?(new) && !text.include?(old)
      raise "[discipline-class] fingerprint missing: #{slug}.#{field}" unless text.scan(old).size == 1

      text = text.sub(old) { new }
      changes += 1
    end
    ac.update_columns(field => text, updated_at: Time.current) if !dry && text != ac.public_send(field).to_s
  end
end
puts "  [discipline-class] #{"DRY_RUN " if dry}changes=#{changes} missing=#{missing.uniq.size}"
