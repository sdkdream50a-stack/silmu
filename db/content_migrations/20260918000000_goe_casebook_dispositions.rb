# 경기도교육청 감사사례집(2021) 기반 재구성 사례 — 처분 절·연도 정정 (2026-09-17 전수감사 G-13)
#
# 원문: 경기도교육청 감사사례집(www.goe.go.kr BBS_202111190247253801.pdf). 사례집 머리말 3항:
#   «사례의 일부를 재구성하고 편집하였기 때문에 처분내용, 처분대상자, 처분 수위 등이 실제 지적사례와 다를 수 있으므로…»
#   연도는 «20××» 로 익명화돼 있다.
# silmu 본문은 원문에 없는 징계(견책·고발·변상 등)와 «2024년 10월» 같은 연도를 덧붙였다.
# 사례 설명문을 원문 항목과 2-gram 대조해 0.5 이상 일치한 50건만 «처분» 절을 원문 처분 문구로 바꾸고, 사건 개요 첫 문장의 연도 머리를 지운다.
# 나머지 12건(일치율 0.5 미만)은 수기 대조 대상으로 남긴다. DRY_RUN=1 이면 쓰지 않는다.

dispositions = [
  [ "goe-2021-annual-leave-compensation-mispayment", "관련자 주의, 과소지급액 추가 지급 및 과다지급액 회수" ],
  [ "goe-2021-bad-debt-write-off-violation", "관련자 주의" ],
  [ "goe-2021-beneficiary-cost-direct-use", "관련자 주의" ],
  [ "goe-2021-beneficiary-cost-settlement", "관련자 주의, 집행잔액 반환" ],
  [ "goe-2021-bid-announcement-period", "관련자 주의" ],
  [ "goe-2021-budget-account-mixed-execution", "관련자 주의" ],
  [ "goe-2021-budget-formation-violation", "관련자 주의" ],
  [ "goe-2021-budget-transfer-violation", "관련자 주의" ],
  [ "goe-2021-building-registration-delay", "관련자 주의" ],
  [ "goe-2021-business-promotion-improper", "관련자 주의, 과다집행액 회수 조치" ],
  [ "goe-2021-clothing-expense-improper", "관련자 경고, 주의 및 회수" ],
  [ "goe-2021-contract-method-2stage-bidding", "관련자 주의" ],
  [ "goe-2021-contract-review-omission", "관련자 주의" ],
  [ "goe-2021-credit-card-payment-account", "관련자 주의" ],
  [ "goe-2021-credit-card-self-inspection", "관련자 주의" ],
  [ "goe-2021-credit-card-usage-improper", "관련자 주의" ],
  [ "goe-2021-daily-audit-89-cases", "기관경고" ],
  [ "goe-2021-development-fund-handover", "관련자 주의" ],
  [ "goe-2021-development-fund-misclassified", "관련자 주의" ],
  [ "goe-2021-development-fund-misuse", "관련자 주의" ],
  [ "goe-2021-disposal-procedure-violation", "관련자 주의" ],
  [ "goe-2021-explicit-carryover-violation", "관련자 주의" ],
  [ "goe-2021-failed-bid-private-contract", "관련자 주의" ],
  [ "goe-2021-family-allowance-misdeclaration", "관련자 주의, 부당수령액 회수" ],
  [ "goe-2021-fiscal-year-independence-violation", "관련자 주의" ],
  [ "goe-2021-foreign-teacher-housing-deposit", "관련자 주의" ],
  [ "goe-2021-gift-voucher-management", "관련자 경고 및 주의" ],
  [ "goe-2021-improper-payee-cleaning-service", "관련자 주의" ],
  [ "goe-2021-improper-payee-personal-card", "관련자 경고" ],
  [ "goe-2021-instructor-allowance-improper", "관련자 주의, 과다지급액 회수" ],
  [ "goe-2021-management-allowance-mispayment", "관련자 주의, 과소지급액 추가지급 및 과다지급액 회수" ],
  [ "goe-2021-misc-allowance-improper", "관련자 주의, 과다지급액 회수" ],
  [ "goe-2021-payment-processing-improper", "관련자 주의, 부당집행액 회수" ],
  [ "goe-2021-performance-bonus-mispayment", "관련자 주의, 과다지급액 회수" ],
  [ "goe-2021-private-contract-2bid-violation", "관련자 주의" ],
  [ "goe-2021-private-contract-s2b-mismatch", "관련자 경고" ],
  [ "goe-2021-reserve-fund-improper", "관련자 주의" ],
  [ "goe-2021-retirement-pension-mismanagement", "관련자 주의" ],
  [ "goe-2021-school-facility-temp-use-permit", "관련자 주의" ],
  [ "goe-2021-specialized-construction-license", "관련자 주의" ],
  [ "goe-2021-split-private-contracts", "관련자 경고" ],
  [ "goe-2021-supplies-joint-purchase", "관련자 주의" ],
  [ "goe-2021-supplies-management-neglect", "관련자 주의" ],
  [ "goe-2021-suspense-cash-embezzlement", "관련자 강등" ],
  [ "goe-2021-suspense-cash-management", "관련자 주의" ],
  [ "goe-2021-suspense-cash-single-approval", "기관통보" ],
  [ "goe-2021-tenure-allowance-mispayment", "관련자 주의, 과소지급액 추가 지급 및 과다지급액 회수" ],
  [ "goe-2021-travel-expense-improper", "관련자 주의, 과다지급액 회수 조치" ],
  [ "goe-2021-vehicle-management-failure", "관련자 주의" ],
  [ "goe-2021-vending-machine-fee-miscalculation", "관련자 주의, 과다징수액 반환" ]
].to_h

note = lambda do |disposition|
  "- 사례집 원문 처분: «#{disposition}» (경기도교육청 감사사례집, 2021)\n" \
    "- 사례집은 사례를 재구성·편집해 처분 내용·대상자·수위가 실제와 다를 수 있다고 밝히고 있습니다. 이 밖의 징계·고발·변상 서술은 원문에 없습니다.\n"
end

section = /(^\#{2,3} 처분(?: 결과)?[ \t]*\n)(.*?)(?=^\#{1,3} |\z)/m
year_head = /(^\#\# 사건 개요[ \t]*\n\s*)20\d\d년[^,\n]{0,25}, /

dry_run = ENV["DRY_RUN"] == "1"
changed = 0

ActiveRecord::Base.transaction do
  dispositions.each do |slug, disposition|
    record = AuditCase.find_by!(slug: slug)
    detail = record.detail.to_s
    raise "DISPOSITION_SECTION_NOT_FOUND #{slug}" unless detail.match?(section)

    updated = detail.sub(section) { "#{Regexp.last_match(1)}#{note.call(disposition)}\n" }
    updated = updated.sub(year_head, '\1')
    next if updated == detail

    record.update_columns(detail: updated, updated_at: Time.current) unless dry_run
    changed += 1
  end
  puts "  [g13-goe] #{dry_run ? 'DRY_RUN ' : ''}changes=#{changed}"
  raise ActiveRecord::Rollback if dry_run
end
