# frozen_string_literal: true

# P1 §23 — 적용 기관 범위 분류기 (HIGH confidence 전용).
#
# 원칙: **부정확한 metadata 는 빈 metadata 보다 위험하다.**
#   구조적으로 확실히 식별되는 신호(기존 sector/org_type enum, 명시적 법령명)만 사용한다.
#   본문 키워드 빈도 같은 약한 신호로 추론하지 않는다 — 애매하면 UNSPECIFIED 를 유지한다.
class AgencyScopeClassifier
  Plan = Struct.new(:record, :target_agency, :jurisdiction, :confidence, :reason, keyword_init: true) do
    def applicable? = confidence == "HIGH" && Array(target_agency).any?

    def attributes_to_apply
      { target_agency: target_agency, jurisdiction: jurisdiction, agency_scope_confidence: confidence }
    end
  end

  # 법령명 → 관할. 해당 법이 적용 대상을 법 자체로 규정하므로 구조적 신호로 볼 수 있다.
  NATIONAL_ONLY_LAWS = [ "국가공무원법", "국가공무원 복무규정", "국가재정법", "국고금관리법" ].freeze
  LOCAL_ONLY_LAWS = [
    "지방공무원법", "지방공무원 복무규정", "지방공무원 보수규정", "지방재정법", "지방회계법",
    "지방자치단체를 당사자로 하는 계약에 관한 법률", "지방계약법"
  ].freeze
  EDUCATION_LAWS = [
    "사립학교법", "초·중등교육법", "유아교육법", "교육공무원법",
    "지방교육자치에 관한 법률", "지방교육재정교부금법"
  ].freeze

  def initialize(record)
    @r = record
  end

  def self.plan_for(record) = new(record).plan

  def plan
    # ① 가장 강한 신호: 기존 sector/org_type enum (사람이 이미 분류해 둔 구조적 값)
    if (from_enum = plan_from_enum)
      return from_enum
    end

    # ② 다음 신호: legal_basis 에 관할이 법으로 규정된 법령만 등장하는 경우
    if (from_law = plan_from_legal_basis)
      return from_law
    end

    Plan.new(record: @r, target_agency: [], jurisdiction: nil, confidence: "LOW",
             reason: "구조적 신호 없음 — UNSPECIFIED 유지 (추론하지 않음)")
  end

  private

  def plan_from_enum
    return nil unless @r.respond_to?(:sector) && @r.sector.present?

    case @r.sector.to_s
    when "edu"
      agencies =
        if @r.respond_to?(:org_type) && @r.org_type.to_s == "school"
          %w[PUBLIC_SCHOOL]
        elsif @r.respond_to?(:org_type) && @r.org_type.to_s == "edu_office"
          %w[EDUCATION_OFFICE EDUCATION_SUPPORT_OFFICE]
        else
          return nil # sector=edu 인데 org_type 미지정 → 학교인지 교육청인지 모른다
        end
      Plan.new(record: @r, target_agency: agencies, jurisdiction: "EDUCATION", confidence: "HIGH",
               reason: "sector=edu + org_type=#{@r.org_type} (기존 구조적 분류값)")
    when "local_gov"
      Plan.new(record: @r, target_agency: %w[LOCAL_GOVERNMENT], jurisdiction: "LOCAL", confidence: "HIGH",
               reason: "sector=local_gov (기존 구조적 분류값)")
    end
  end

  def plan_from_legal_basis
    basis = @r.respond_to?(:legal_basis) ? @r.legal_basis : nil
    return nil if basis.blank?

    names = LegalReferenceResolver.resolve(basis)
                                  .select { |x| x.confidence == "HIGH" }
                                  .map { |x| x.canonical_name.to_s }
    return nil if names.empty?

    has_national = names.any? { |n| NATIONAL_ONLY_LAWS.any? { |l| n.start_with?(l) } }
    has_local    = names.any? { |n| LOCAL_ONLY_LAWS.any? { |l| n.start_with?(l) } }
    has_edu      = names.any? { |n| EDUCATION_LAWS.any? { |l| n.start_with?(l) } }

    # 교육 법령이 섞이면 학교/교육청 구분이 필요한데 그건 여기서 알 수 없다 → 판정 보류
    return nil if has_edu
    # 국가·지방이 함께 나오면 어느 쪽 독자인지 알 수 없다 → 판정 보류 (P0 TR-06 이 바로 이 상황)
    return nil if has_national && has_local

    if has_local
      Plan.new(record: @r, target_agency: %w[LOCAL_GOVERNMENT], jurisdiction: "LOCAL", confidence: "HIGH",
               reason: "legal_basis 가 지방 전용 법령만 인용 (#{names.first})")
    elsif has_national
      Plan.new(record: @r, target_agency: %w[CENTRAL_GOVERNMENT], jurisdiction: "NATIONAL", confidence: "HIGH",
               reason: "legal_basis 가 국가 전용 법령만 인용 (#{names.first})")
    end
  end
end
