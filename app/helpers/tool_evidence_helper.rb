# frozen_string_literal: true

# PHASE C — 도구 결과의 «다음 칸» 연결 (17_UIUX_PERSONA_AUDIT TOP10).
#
# 운영 실측(2026-09-18): 도구 4/4 의 결과 화면에 **감사사례 0 · 서식 0** 이었다.
# 사용자가 요구한 흐름은 «질문 → 답 → 판정/계산 → 공식근거 → 서식 → 감사사례» 인데
# 마지막 두 칸이 끊겨 있어, 계산은 되지만 «그래서 무엇을 쓰고 무엇을 조심하나» 로 이어지지 않았다.
#
# ── 왜 자동 유사도를 쓰지 않는가
#   감사 기록(17 §2-G)에 이미 실패 사례가 있다: 학교발전기금 토픽의 «유사 감사사례» 가
#   이중계상·출장비·가족수당이었다. 무관한 사례를 붙이면 신뢰를 깎는다.
#   그래서 **손으로 확인한 매핑만** 둔다. 매핑이 없는 도구는 아무것도 붙지 않는다(빈칸이 거짓보다 낫다).
#
# ── 선정 규칙
#   · 교육(sector=edu) 사례를 먼저 고른다 — 이 사이트의 대상이 학교 행정실이다.
#   · 원문 근거형(ACTUAL_AUDIT)을 재구성형보다 먼저 고른다.
#   · 재구성·가상 사례를 붙일 때도 감추지 않는다 — 카드에 출처 칩이 붙는다(G-65).
#   · slug·서식 id 는 전부 운영에서 존재를 확인했다. 테스트가 그 존재를 다시 강제한다.
module ToolEvidenceHelper
  # tool_key => { audit_case: [slug, 제목], template: [id, 제목] }
  TOOL_EVIDENCE = {
    "contract-method" => {
      audit_case: [ "sen-2025-school-i-split-private-disability",
                    "분할수의계약 지적 — 장애인기업 5천만 초과" ],
      template:   [ 18, "수의계약 사유서" ]
    },
    "split-contract-checker" => {
      audit_case: [ "sen-2025-school-i-split-private-disability",
                    "분할수의계약 지적 — 장애인기업 5천만 초과" ],
      template:   [ 18, "수의계약 사유서" ]
    },
    "overtime-calculator" => {
      audit_case: [ "silmu-2026-overtime-post-approval",
                    "사후 시간외근무명령 결재 — 사전 결재 원칙 위반" ],
      template:   nil
    },
    "travel-calculator" => {
      audit_case: [ "goe-2021-travel-expense-improper",
                    "여비 지급 부적정 — 근무지내 출장 정액 초과·증빙 미비" ],
      template:   [ 21, "출장 복명서" ]
    },
    "annual-leave-calculator" => {
      audit_case: [ "goe-2021-annual-leave-compensation-mispayment",
                    "연가보상비 지급 부적정 — 병가 미제외·보상일수 착오" ],
      template:   nil
    },
    "budget-transfer-checker" => {
      audit_case: [ "goe-2021-budget-transfer-violation",
                    "학교(교비)회계 예산 이·전용 업무처리 부적정" ],
      template:   nil
    }
  }.freeze

  # 도구 «다음 단계» 카드에 덧붙일 슬롯. 매핑이 없으면 빈 배열이다.
  def tool_evidence_slots(tool_key)
    entry = TOOL_EVIDENCE[tool_key.to_s]
    return [] if entry.blank?

    slots = []
    if (ac = entry[:audit_case])
      slots << { type: "audit_case", path: audit_case_path(slug: ac[0]),
                 label: "이 계산에서 나온 지적", title: ac[1],
                 # color 는 Tailwind 가 **동적 클래스를 purge** 하므로 빌드된 CSS 에 실제로
                 # 있는 값만 쓴다. 2026-09-18 실측: hover:border-rose-400 는 CSS 에 없어서
                 # rose 카드만 hover 테두리가 죽는다. amber 는 다른 카드가 이미 써서 살아 있다.
                 desc: "같은 실수를 미리 확인하세요", icon: "gavel", color: "amber" }
    end
    if (t = entry[:template])
      slots << { type: "template", path: template_path(t[0]),
                 label: "함께 쓰는 서식", title: t[1],
                 desc: "미리보기·인쇄", icon: "description", color: "blue" }
    end
    slots
  end
end
