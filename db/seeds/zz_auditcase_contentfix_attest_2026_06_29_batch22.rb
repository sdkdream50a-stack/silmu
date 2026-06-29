# frozen_string_literal: true

# 2026-06-29 E-E-A-T content-fix(본문 authoring) 후 attest 배치22 — 단건 budget 이용/전용 개념 정정.
#
# ⚠️ 무결성 원칙(배치6/12~21과 동일): 합성 콘텐츠. 정직 공시. content-fix=update!(IndexNow), attest=update_columns.
#
# 1차출처 대조 확정(LBOX/law.go.kr, 2026-06-29):
#   지방재정법 §47의2=예산의 이용·이체 (정책사업 "간" 융통 = 이용; 원칙 금지, 미리 예산으로 지방의회 의결 거친 경우만 가능)
#   지방재정법 §49=예산의 전용 (각 정책사업 "내" 단위사업/목 간 = 전용; 기관장 권한, §49② 제약+분기 보고)
#
# 정정 사유: 본 사례=도로보수(정책사업 A)→사무실리모델링(정책사업 B)=정책사업 간=이용(§47의2, 의회 의결 필요)인데
#   기존 본문이 전부 "전용 §49"로 오기. 단 lesson §2 "동일 정책사업 내 전용=기관장 승인"·§3 인건비 전용 제한은 §49로 정확 → 보존.
#   기계 치환 시 정확한 §49 대조문이 파손되므로 필드별 전체 값 명시 authoring.
#
# 변경: title·legal_basis·issue·detail·lesson·action_taken·checkpoints (위반 표현 전용→이용, 대조 §49 보존).

slug = "budget-unauthorized-transfer"

NEW = {
  title: "예산 목적 외 사용 (의회 의결 없는 이용)",
  legal_basis: "지방재정법 제47조의2(예산의 이용·이체), 제49조(예산의 전용)",
  issue: "도로 보수 예산 8,000만원을 의회 의결 없이 사무실 리모델링에 이용(移用)하여 사용함. 정책사업 간 이용은 의회 의결이 필요하나, 내부 결재만으로 예산을 목적 외에 사용한 사례.",
  detail: <<~MD.strip,
    ## 사건 개요

    2024년 6월, ○○군은 도로 보수 예산 8,000만원이 집행이 부진한 상태에서 노후 사무실 리모델링이 시급하다는 판단을 했습니다.

    담당자 A씨는 도로 보수 예산(정책사업 A)에서 사무실 리모델링(정책사업 B)으로 예산을 이용(移用)하기로 했습니다. A씨는 군의회 의결을 거치지 않고 내부 결재만으로 이용을 처리했습니다.

    ### 감사 적발 경위

    연말 예산 집행 결과를 점검하던 감사관이 예산 이용 내역을 확인했습니다.

    - 이용 전: 도로 보수 예산 8,000만원
    - 이용 후: 사무실 리모델링 예산 8,000만원
    - 이용 유형: 정책사업 간 이용 (의회 의결 필요)
    - 의회 의결 여부: 없음
    - 내부 결재: 있음

    ### 처벌 및 조치 결과

    A씨는 감봉 처분(중징계)을 받았습니다. 이용된 예산에 대한 원상 복구 조치가 이루어졌고 의회에 사후 보고가 제출되었습니다. 예산 이용·전용 절차 재교육이 실시되었습니다.

    ### 사건이 주는 교훈

    예산은 의회가 승인한 목적과 사업에만 사용해야 합니다. 정책사업 간 이용은 의회의 예산 통제권을 우회하는 행위로, 지방재정법의 엄격한 규제를 받습니다.
  MD
  lesson: <<~MD.strip,
    ## 실무자가 반드시 알아야 할 3가지

    ### 1. 정책사업 간 이용(移用)은 반드시 의회 의결이 필요합니다
    지방재정법 제47조의2는 정책사업 간 예산 이용을 의회 의결 사항으로 규정합니다. 내부 결재만으로 처리하면 의회의 예산 통제권을 침해하는 것으로 법 위반입니다.

    ### 2. 동일 정책사업 내 단위사업 간 전용은 기관장 승인으로 가능합니다
    같은 정책사업 내에서 단위사업 간 예산을 조정하는 전용(轉用)은 지방재정법 제49조에 따라 기관장의 결재로 가능합니다. 예산 조정 전에 정책사업 간 이용인지 정책사업 내 전용인지 먼저 판단해야 합니다.

    ### 3. 인건비·업무추진비로의 전용은 추가 제한이 있습니다
    인건비나 업무추진비로 예산을 전용하는 것은 유형에 상관없이 추가적인 제한이 있습니다. 전용 가능 여부를 먼저 법령에서 확인하세요.

    **예산을 이용·전용하기 전에 의회 의결이 필요한 유형(정책사업 간 이용)인지 반드시 확인하세요. 무의결 이용은 중징계와 원상복구입니다.**
  MD
  action_taken: "관련자 중징계(감봉), 예산 원상 복구 조치, 의회 사후 보고, 예산 이용·전용 절차 재교육",
  checkpoints: [
    { "icon" => "account_balance", "title" => "이용·전용 구분 확인", "desc" => "정책사업 간(이용)·내(전용)인지 구분하여 승인 절차를 확인" },
    { "icon" => "approval", "title" => "의회 의결 여부", "desc" => "정책사업 간 이용 시 의회 의결을 받았는지 확인" },
    { "icon" => "rule", "title" => "전용 제한 확인", "desc" => "인건비·업무추진비로의 전용 등 제한 사항을 확인" },
    { "icon" => "edit_document", "title" => "이용·전용 사유 기록", "desc" => "이용·전용 사유와 필요성이 문서화되었는지 확인" }
  ]
}.freeze

method = "law.go.kr legal_basis 검증"
abort "❌ method 32자 초과: #{method.length}" if method.length > 32
prefix = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
suffix = ". 운영 정합"
verified_at = Date.new(2026, 6, 29)

a = AuditCase.find_by(slug: slug)
abort "❌ 미발견: #{slug}" if a.nil?

a.update!(NEW)
a.reload

# 잔존 검산: 위반(정책사업 간) 표현이 여전히 "전용"으로 남았는지 — §49 대조문이 아닌 곳
problems = []
problems << "issue에 '간 전용' 잔존" if a.issue.include?("간 전용")
problems << "legal_basis 구 §49 단독" unless a.legal_basis.include?("제47조의2")
problems << "detail '간 전용' 잔존" if a.detail.include?("간 전용")
# §49 대조문 보존 확인(있어야 정상)
problems << "lesson §2 전용 대조 소실" unless a.lesson.include?("동일 정책사업 내 단위사업 간 전용은 기관장")

lb = a.legal_basis.to_s.strip
src_budget = 200 - prefix.length - suffix.length
lb_fit = lb.length > src_budget ? lb[0, src_budget - 1] + "…" : lb
src = "#{prefix}#{lb_fit}#{suffix}"
attested = false
if src.length <= 200
  a.update_columns(verification_source: src, verification_method: method, last_verified_at: verified_at)
  attested = true
else
  problems << "src#{src.length}>200"
end

puts "✅ content-fix(budget 이용/전용 정정) 적용 + attest=#{attested} (배치22)"
puts "   legal_basis: #{a.legal_basis}"
puts(problems.any? ? "⛔ 검산 문제: #{problems.join(', ')}" : "✅ 검산 CLEAN(위반=이용 표기·§49 대조 보존)")
