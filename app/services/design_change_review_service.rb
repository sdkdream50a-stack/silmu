# 설계변경 검토서 도우미 서비스
# 설계변경 사유별 검토서 및 절차 체크리스트 생성
class DesignChangeReviewService
  # 설계변경 사유 유형
  CHANGE_REASONS = {
    site_condition: {
      name: "현장여건 상이",
      icon: "landscape",
      desc: "실제 현장이 설계도서와 다른 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제1호",
      legal_text: "공사현장의 상태가 설계서와 다른 경우",
      documents: [
        "현장 상태 확인서 (사진 포함)",
        "당초 설계도서",
        "현장 측량 성과",
        "설계변경 사유서",
        "변경설계도면",
        "변경 수량산출서"
      ],
      cautions: [
        "현장 상이 사실을 즉시 감독관에게 서면 통보해야 함",
        "통보 전 임의시공 시 설계변경 불인정 가능",
        "사진·측량 등 객관적 증빙 확보 필수",
        "당초 설계서와의 차이를 구체적으로 명시"
      ]
    },
    design_error: {
      name: "설계서 오류·누락",
      icon: "bug_report",
      desc: "설계도서에 오류나 누락이 있는 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제2호",
      legal_text: "설계서의 내용이 불분명하거나 누락·오류가 있는 경우",
      documents: [
        "설계오류 확인서",
        "당초 설계도서 (오류 부분 표시)",
        "설계변경 사유서",
        "변경설계도면",
        "변경 수량산출서",
        "설계자 의견서 (필요 시)"
      ],
      cautions: [
        "설계오류의 구체적 내용과 영향범위 명시",
        "오류 발견 즉시 감독관에게 통보",
        "설계자 귀책사유 해당 시 설계자에게 보수 없이 변경설계 요구 가능",
        "오류로 인한 기시공 부분 처리방안도 함께 검토"
      ]
    },
    civil_request: {
      name: "민원 요청",
      icon: "people",
      desc: "주민 민원으로 설계 변경이 필요한 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제5호",
      legal_text: "기타 발주기관이 설계변경이 필요하다고 인정하는 경우",
      documents: [
        "민원 접수서 (신청서·진정서 등)",
        "민원 검토 의견서",
        "설계변경 사유서",
        "변경설계도면",
        "변경 수량산출서",
        "관련 부서 협의서"
      ],
      cautions: [
        "민원 타당성을 객관적으로 검토·기록",
        "민원으로 인한 설계변경은 발주자 귀책으로 볼 수 있음",
        "공기 연장 사유에 해당할 수 있으므로 공정표 검토",
        "비용 증가 시 예산 확보 방안 사전 검토"
      ]
    },
    quantity_change: {
      name: "물량 변경",
      icon: "straighten",
      desc: "시공 수량이 설계와 다른 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제3호",
      legal_text: "물량의 증감이 발생한 경우",
      documents: [
        "당초 수량산출서",
        "변경 수량산출서",
        "실측 자료 (사진·도면)",
        "설계변경 사유서",
        "단가 산출 근거"
      ],
      cautions: [
        "증감 수량의 실측 근거 명확히 확보",
        "단순 물량 증감은 총공사비의 10% 이내에서 가능",
        "10% 초과 시 별도 계약 체결 검토",
        "감액 설계변경 시에도 동일 절차 필요"
      ]
    },
    method_change: {
      name: "공법 변경",
      icon: "engineering",
      desc: "시공 공법을 변경해야 하는 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제4호",
      legal_text: "새로운 기술·공법 사용으로 공사비 절감이 가능한 경우",
      documents: [
        "공법 변경 검토서",
        "당초 공법 대비 비교표",
        "변경 공법 기술자료",
        "설계변경 사유서",
        "변경설계도면",
        "변경 수량산출서",
        "VE(가치공학) 검토서 (해당 시)"
      ],
      cautions: [
        "변경 공법의 안전성·품질 동등 이상 입증 필요",
        "공사비 절감 효과 산출 (시공자 제안 시 절감액 배분)",
        "특허공법 사용 시 지식재산권 확인",
        "관련 기술기준·시방서 적합성 확인"
      ]
    },
    other: {
      name: "기타 사유",
      icon: "more_horiz",
      desc: "기타 설계변경이 필요한 경우",
      legal_basis: "지방계약법 시행령 제65조 제1항 제5호",
      legal_text: "기타 발주기관이 설계변경이 필요하다고 인정하는 경우",
      documents: [
        "설계변경 사유서 (상세)",
        "관련 증빙자료",
        "변경설계도면",
        "변경 수량산출서",
        "관련 부서 협의서"
      ],
      cautions: [
        "변경 사유의 정당성을 충분히 소명",
        "감사 지적 대비 객관적 근거 확보",
        "계약상대자와의 협의 내용 기록",
        "관련 법령·지침 검토 후 진행"
      ]
    }
  }.freeze

  # 설계변경 절차 체크리스트
  PROCEDURE_CHECKLIST = [
    { step: 1, name: "변경사유 발생·통보", desc: "현장에서 변경 사유 발생 시 감독관에게 서면 통보", responsible: "시공자→감독관" },
    { step: 2, name: "설계변경 검토", desc: "변경 사유의 타당성, 범위, 예산 등 검토", responsible: "감독관·담당부서" },
    { step: 3, name: "설계변경 승인", desc: "설계변경 시행 여부 결정 (기안·결재)", responsible: "발주부서장" },
    { step: 4, name: "변경설계 시행", desc: "변경도면, 수량산출서, 내역서 작성", responsible: "설계자/시공자" },
    { step: 5, name: "변경금액 산정", desc: "증감 금액 산출 (계약단가·신규단가 적용)", responsible: "원가부서/담당자" },
    { step: 6, name: "변경계약 체결", desc: "계약금액 변경 계약서 작성·서명", responsible: "계약부서" }
  ].freeze

  # 비용 영향 유형
  COST_IMPACTS = {
    increase: { name: "증액", icon: "trending_up", color: "red" },
    decrease: { name: "감액", icon: "trending_down", color: "green" },
    same: { name: "동일 (공법 변경 등)", icon: "trending_flat", color: "gray" }
  }.freeze

  class << self
    def get_change_reasons
      CHANGE_REASONS.map { |key, val| { id: key.to_s, name: val[:name], icon: val[:icon], desc: val[:desc] } }
    end

    def get_reason_detail(reason_id)
      reason = CHANGE_REASONS[reason_id.to_s.to_sym]
      return { success: false, error: "유효하지 않은 변경사유입니다." } unless reason

      {
        success: true,
        reason: reason.merge(id: reason_id),
        procedure: PROCEDURE_CHECKLIST,
        cost_impacts: COST_IMPACTS.map { |k, v| v.merge(id: k.to_s) }
      }
    end

    def generate(params)
      reason_id = params[:reason].to_s.to_sym
      return { success: false, error: "유효하지 않은 변경사유입니다." } unless CHANGE_REASONS.key?(reason_id)

      reason = CHANGE_REASONS[reason_id]
      cost_impact = params[:cost_impact] || "same"
      change_amount = params[:change_amount].to_i
      schedule_change = params[:schedule_change] == "true" || params[:schedule_change] == true
      schedule_days = params[:schedule_days].to_i

      {
        success: true,
        review: {
          reason: reason.merge(id: reason_id.to_s),
          original_design: params[:original_design].to_s,
          changed_design: params[:changed_design].to_s,
          detail_reason: params[:detail_reason].to_s,
          cost_impact: COST_IMPACTS[cost_impact.to_sym] || COST_IMPACTS[:same],
          change_amount: change_amount,
          schedule_change: schedule_change,
          schedule_days: schedule_days,
          documents: reason[:documents],
          cautions: reason[:cautions],
          procedure: PROCEDURE_CHECKLIST,
          legal_basis: reason[:legal_basis],
          legal_text: reason[:legal_text]
        }
      }
    end
  end
end
