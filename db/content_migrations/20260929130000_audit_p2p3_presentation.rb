# 감사사례 P2/P3 표시층 정정 — 조치내용·관련 토픽·출처 쪽수 (2026-09-29)
#
# 입력: tasks/silmu-audit-case-truth-closure-0929/workers/*/verdicts.md 의 P2·P3 42건(원문 PDF 대조 완료).
# 본문(issue·detail·lesson·legal_basis·checkpoints)은 건드리지 않는다 — text FIX 는 20260929120000·121000 이 맡는다.
#
# 1) action_taken: 42건 모두 비어 있어 «조치내용» 칸이 빈 채로 렌더됐다(원문 처분은 상세 분석 «처분» 줄에만 있음).
#    값 = 원문 처분 문구 — 경기 = 20260918000000·010000 에서 원문과 대조해 넣은 처분 문구, 서울 = 운영 상세 분석 «처분» 줄
#    (verdicts ACTION_SUPPORTED=Y). 새 처분을 만들지 않는다. 쉼표는 뷰에서 항목 구분자다.
# 2) topic_slug: 관련 토픽이 없던 사례 중 개념이 직접 대응하는 것만 1개 연결(토픽 쪽 «관련 감사사례»에도 나타난다).
#    지방계약법 기준 토픽은 국가계약법을 따르는 서울 사립 사례에 연결하지 않는다(법령 무관 토픽만).
# 3) source_page: 출처 쪽수 1쪽 차이 3건(원문 인쇄 쪽 기준).
#
# 이미 목표값이면 건너뛴다. 현재값이 기대한 옛 값이 아니면 전체 롤백. DRY_RUN=1 이면 쓰지 않는다.
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929130000_audit_p2p3_presentation.rb})"'
#   → 기대 changes=64 (action_taken 42 · topic_slug 19 · source_page 3) · 두 번째 실행 changes=0
# 롤백: action_taken → nil · topic_slug → nil · source_page → old.

actions = {
  "goe-2021-accounting-disorder-construction" => "담당자 주의, 관리자 경고",
  "goe-2021-annual-leave-compensation-mispayment" => "관련자 주의, 과소지급액 추가 지급 및 과다지급액 회수",
  "goe-2021-bad-debt-write-off-violation" => "관련자 주의",
  "goe-2021-beneficiary-cost-settlement" => "관련자 주의, 집행잔액 반환",
  "goe-2021-budget-account-mixed-execution" => "관련자 주의",
  "goe-2021-budget-transfer-violation" => "관련자 주의",
  "goe-2021-building-registration-delay" => "관련자 주의",
  "goe-2021-business-promotion-improper" => "관련자 주의, 과다집행액 회수 조치",
  "goe-2021-clothing-expense-improper" => "관련자 경고, 주의 및 회수",
  "goe-2021-condolence-money-improper" => "담당자 주의, 부당집행액 회수 조치",
  "goe-2021-contract-review-omission" => "관련자 주의",
  "goe-2021-credit-card-usage-improper" => "관련자 주의",
  "goe-2021-development-fund-handover" => "관련자 주의",
  "goe-2021-development-fund-misclassified" => "관련자 주의",
  "goe-2021-development-fund-misuse" => "관련자 주의",
  "goe-2021-disposal-procedure-violation" => "관련자 주의",
  "goe-2021-failed-bid-private-contract" => "관련자 주의",
  "goe-2021-improper-payee-cleaning-service" => "관련자 주의",
  "goe-2021-improper-payee-personal-card" => "관련자 경고",
  "goe-2021-instructor-allowance-improper" => "관련자 주의, 과다지급액 회수",
  "goe-2021-special-duty-allowance-mispayment" => "현지조치, 과소지급액 추가 지급 및 과다지급액 회수",
  "goe-2021-split-after-school-program" => "관련자 주의, 관리자(교장) 경고",
  "goe-2021-split-care-trip-copier-paint" => "관련자 주의",
  "goe-2021-supplies-joint-purchase" => "관련자 주의",
  "goe-2021-supplies-selection-committee" => "관련자 주의",
  "goe-2021-tenure-allowance-mispayment" => "관련자 주의, 과소지급액 추가 지급 및 과다지급액 회수",
  "goe-2021-travel-expense-improper" => "관련자 주의, 과다지급액 회수 조치",
  "goe-2021-vending-machine-fee-miscalculation" => "관련자 주의, 과다징수액 반환",
  "sen-2025-foundation-y-audit-omission" => "기관주의",
  "sen-2025-school-y-handover" => "기관주의",
  "sen-2025-school-i-split-private-disability" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-c-development-fund-misuse" => "주의 요구 — 학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-c-electrical-separate-order" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-c-school-council-composition" => "기관주의",
  "sen-2025-school-v-budget-pre-execution" => "학교법인 이사장 → 관련자 \"경고\" 처분",
  "sen-2025-school-v-facility-split-private" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-y-vehicle-leave-violation" => "기관주의",
  "sen-2025-school-s-disaster-prevention" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-s-service-contract-violation" => "학교법인 이사장 → 관련자 \"경고\" 처분",
  "sen-2025-school-s-supply-direct-prod-cert" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-c-facility-design-document" => "학교법인 이사장 → 관련자 \"주의\" 처분",
  "sen-2025-school-c-long-term-contract-violation" => "학교법인 이사장 → 관련자 \"경고\" 처분"
}.freeze

topics = {
  "goe-2021-accounting-disorder-construction" => "inspection",
  "goe-2021-annual-leave-compensation-mispayment" => "annual-leave",
  "goe-2021-budget-account-mixed-execution" => "budget-item-standard",
  "goe-2021-budget-transfer-violation" => "budget-transfer",
  "goe-2021-building-registration-delay" => "public-property-management",
  "goe-2021-business-promotion-improper" => "entertainment-expense-rules",
  "goe-2021-clothing-expense-improper" => "entertainment-expense-rules",
  "goe-2021-condolence-money-improper" => "entertainment-expense-rules",
  "goe-2021-development-fund-misclassified" => "extra-budgetary-fund",
  "goe-2021-failed-bid-private-contract" => "bid-failure-negotiation",
  "goe-2021-improper-payee-cleaning-service" => "payment",
  "goe-2021-improper-payee-personal-card" => "payment",
  "goe-2021-split-after-school-program" => "split-contract",
  "goe-2021-split-care-trip-copier-paint" => "split-contract",
  "goe-2021-supplies-joint-purchase" => "goods-selection-committee",
  "goe-2021-supplies-selection-committee" => "goods-selection-committee",
  "goe-2021-travel-expense-improper" => "travel-expense",
  "goe-2021-vending-machine-fee-miscalculation" => "public-property-management",
  "sen-2025-school-s-supply-direct-prod-cert" => "direct-production-confirm"
}.freeze

# [old, new] — 원문 인쇄 쪽(verdicts: annual-leave p.130 · special-duty p.127 · tenure p.126)
pages = {
  "goe-2021-annual-leave-compensation-mispayment" => [ 129, 130 ],
  "goe-2021-special-duty-allowance-mispayment" => [ 126, 127 ],
  "goe-2021-tenure-allowance-mispayment" => [ 125, 126 ]
}.freeze

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  (actions.keys | topics.keys | pages.keys).each do |slug|
    record = AuditCase.find_by(slug: slug)
    raise "[audit-p2p3-presentation] missing case: #{slug}" unless record

    to_write = {}
    if (want = actions[slug]) && record.action_taken != want
      raise "[audit-p2p3-presentation] action_taken not blank: #{slug}" if record.action_taken.present?

      to_write["action_taken"] = want
    end
    if (want = topics[slug]) && record.topic_slug != want
      raise "[audit-p2p3-presentation] topic_slug already set: #{slug}=#{record.topic_slug}" if record.topic_slug.present?
      raise "[audit-p2p3-presentation] topic missing: #{want}" unless Topic.published.exists?(slug: want)

      to_write["topic_slug"] = want
    end
    if (old, new = pages[slug]) && record.source_page != new
      raise "[audit-p2p3-presentation] source_page mismatch: #{slug}=#{record.source_page}" unless record.source_page == old

      to_write["source_page"] = new
    end
    next if to_write.empty?

    changes += to_write.size
    puts "  [audit-p2p3-presentation] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    record.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-p2p3-presentation] #{"DRY_RUN " if dry}changes=#{changes}"
