class TemplatesController < ApplicationController
  TEMPLATES = [
    # 물품 관련 양식
    { id: 1, title: "물품구매 표준계약서", desc: "물품 구매 시 사용하는 표준 계약서 양식", category: "계약서", formats: ["HWP", "PDF"], color: "point", badge: "인기" },
    { id: 2, title: "수의계약 통합서약서", desc: "청렴계약, 노무비 지급 등 통합 서약서", category: "계약서", formats: ["HWP", "PDF"], color: "forest", badge: "인기" },
    { id: 3, title: "물품 검사검수조서", desc: "물품 납품 시 검수 확인 양식", category: "검수조서", formats: ["HWP", "XLSX"], color: "warm" },
    { id: 4, title: "물품 납품확인서", desc: "물품 납품 완료 확인 양식", category: "검수조서", formats: ["HWP", "PDF"], color: "navy" },
    { id: 5, title: "대금청구서", desc: "계약대금 청구 시 사용하는 양식", category: "계약서", formats: ["HWP", "XLSX"], color: "point" },

    # 용역 관련 양식
    { id: 6, title: "용역 표준계약서", desc: "일반용역 계약 시 사용하는 표준 양식", category: "계약서", formats: ["HWP", "PDF"], color: "forest", badge: "NEW" },
    { id: 7, title: "착수계", desc: "용역 착수 신고 양식", category: "기안문", formats: ["HWP"], color: "warm" },
    { id: 8, title: "준공계", desc: "용역 완료 신고 양식", category: "기안문", formats: ["HWP"], color: "navy" },
    { id: 9, title: "노무비 지급확인서", desc: "노무비 지급 확인 양식 (건설근로자)", category: "계약서", formats: ["HWP", "XLSX"], color: "point" },
    { id: 10, title: "하도급대금 직접지급확인서", desc: "하도급대금 직접지급 관련 양식", category: "계약서", formats: ["HWP", "PDF"], color: "forest" },

    # 공사 관련 양식
    { id: 11, title: "착공계", desc: "공사 착공 신고 양식", category: "기안문", formats: ["HWP", "PDF"], color: "warm", badge: "NEW" },
    { id: 12, title: "준공검사조서", desc: "공사 준공 검사 결과 양식", category: "검수조서", formats: ["HWP", "PDF"], color: "navy" },
    { id: 13, title: "안전점검 체크리스트", desc: "공사현장 안전점검 체크리스트", category: "기타", formats: ["HWP", "XLSX"], color: "point" },
    { id: 14, title: "하자보증서", desc: "공사 하자보증 관련 양식", category: "계약서", formats: ["HWP", "PDF"], color: "forest" },
    { id: 15, title: "기성검사조서", desc: "공사 기성금 검사 양식", category: "검수조서", formats: ["HWP", "XLSX"], color: "warm" },
    { id: 16, title: "설계변경 요청서", desc: "공사 설계변경 요청 양식", category: "기안문", formats: ["HWP"], color: "navy" },

    # 기존 양식
    { id: 17, title: "물품 구매 기안문", desc: "표준 물품 구매를 위한 품의 및 기안 양식", category: "기안문", formats: ["HWP", "PDF"], color: "point" },
    { id: 18, title: "수의계약 사유서", desc: "수의계약 시 필요한 사유서 양식", category: "계약서", formats: ["HWP", "DOCX"], color: "forest" },
    { id: 19, title: "견적서", desc: "2인 이상 견적서 표준 양식", category: "계약서", formats: ["HWP", "XLSX"], color: "navy" },
    { id: 20, title: "예정가격조서", desc: "예정가격 산정을 위한 조서 양식", category: "계약서", formats: ["HWP", "PDF"], color: "point" },
    { id: 21, title: "출장 복명서", desc: "국내/국외 출장 복명서 양식", category: "기안문", formats: ["HWP"], color: "forest" },
    { id: 22, title: "업무 인수인계서", desc: "직위 변경 시 업무 인수인계 양식", category: "기타", formats: ["HWP", "DOCX"], color: "warm" },
    { id: 23, title: "회의록", desc: "각종 회의 결과 기록 양식", category: "기타", formats: ["HWP", "PDF"], color: "navy" },
  ].freeze

  def index
    @templates = TEMPLATES
    set_meta_tags(
      title: "문서 양식",
      description: "계약서, 검수조서, 기안문, 사유서 등 공무원 업무에 필요한 23종 문서 양식을 무료로 다운로드하세요.",
      keywords: "문서 양식, 계약서, 검수조서, 기안문, 수의계약 사유서, 견적서, 예정가격조서",
      og: {
        title: "문서 양식 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    )
  end

  def show
    @template = TEMPLATES.find { |t| t[:id] == params[:id].to_i }

    if @template.nil?
      redirect_to templates_path, alert: "양식을 찾을 수 없습니다."
      return
    end

    set_meta_tags(
      title: @template[:title],
      description: "#{@template[:desc]} — #{@template[:formats].join(', ')} 형식 무료 다운로드",
      keywords: "#{@template[:title]}, #{@template[:category]}, 양식 다운로드",
      og: {
        title: "#{@template[:title]} — 실무.kr",
        description: @template[:desc],
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    )

    # 관련 양식 (같은 카테고리에서 현재 양식 제외하고 4개)
    @related_templates = TEMPLATES
      .select { |t| t[:category] == @template[:category] && t[:id] != @template[:id] }
      .first(4)

    # 관련 양식이 4개 미만이면 다른 카테고리에서 채움
    if @related_templates.length < 4
      others = TEMPLATES
        .reject { |t| t[:id] == @template[:id] || @related_templates.include?(t) }
        .first(4 - @related_templates.length)
      @related_templates += others
    end
  end
end
