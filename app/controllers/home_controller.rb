class HomeController < ApplicationController
  # 월별 × sector 큐레이션 매핑
  # 값: topic slug 배열 (시즌에 맞는 주요 토픽)
  SEASONAL_TOPICS = {
    local_gov: {
      1  => %w[year-end-settlement budget-carryover payment inspection],
      2  => %w[year-end-settlement budget-carryover private-contract],
      3  => %w[budget-carryover private-contract bidding contract-execution],
      4  => %w[bidding contract-execution estimated-price private-contract],
      5  => %w[inspection payment contract-guarantee-deposit advance-payment],
      6  => %w[inspection payment design-change late-penalty],
      7  => %w[budget-carryover inspection bidding],
      8  => %w[bidding estimated-price contract-execution],
      9  => %w[bidding contract-execution private-contract],
      10 => %w[inspection payment late-penalty completion-payment-checklist],
      11 => %w[budget-carryover year-end-settlement inspection payment],
      12 => %w[year-end-settlement budget-carryover inspection payment],
    },
    edu: {
      # 학교회계: 회계연도 3.1~다음해 2.28 (초중등교육법 제30조의2)
      # 교육비특별회계(교육청): 1.1~12.31 — budget-compilation 유지
      1  => %w[year-end-settlement budget-carryover payment inspection],
      2  => %w[goods-selection-committee goods-selection-committee private-contract bidding],
      3  => %w[goods-selection-committee goods-selection-committee private-contract bidding],
      4  => %w[goods-selection-committee estimated-price bidding contract-execution],
      5  => %w[inspection payment advance-payment contract-guarantee-deposit],
      6  => %w[inspection payment design-change],
      7  => %w[budget-carryover bidding inspection],
      8  => %w[bidding estimated-price private-contract],
      9  => %w[goods-selection-committee bidding contract-execution goods-selection-committee],
      10 => %w[goods-selection-committee inspection payment late-penalty],
      11 => %w[goods-selection-committee year-end-settlement inspection],
      12 => %w[year-end-settlement budget-carryover payment],
    },
    common: {
      1  => %w[year-end-settlement budget-carryover payment inspection],
      2  => %w[private-contract bidding year-end-settlement],
      3  => %w[private-contract bidding contract-execution estimated-price],
      4  => %w[bidding contract-execution private-contract estimated-price],
      5  => %w[inspection payment advance-payment contract-guarantee-deposit],
      6  => %w[inspection payment design-change late-penalty],
      7  => %w[budget-carryover bidding inspection],
      8  => %w[bidding estimated-price private-contract contract-execution],
      9  => %w[bidding contract-execution private-contract],
      10 => %w[inspection payment late-penalty completion-payment-checklist],
      11 => %w[budget-carryover year-end-settlement private-contract],
      12 => %w[year-end-settlement budget-carryover payment inspection],
    }
  }.freeze

  # SEASONAL_TOPICS 변경 시 이 값을 올리면 캐시 자동 무효화
  CURATION_VERSION = 3

  def index
    @sector = resolve_sector

    # 전체 통계 카운트 (sector 무관)
    @topic_count      = Rails.cache.fetch("stats/topic_count", expires_in: 30.minutes) { Topic.published.count }
    @guide_count      = Rails.cache.fetch("stats/guide_count", expires_in: 30.minutes) { Guide.published.count }
    @audit_case_count = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }
    @template_count   = TemplatesController::TEMPLATES.count

    # sector별 월별 큐레이션 토픽
    current_month = Time.zone.now.month
    curated_version = Rails.cache.read("home/curated_version") || 0
    cache_key = "home/curated/cv#{CURATION_VERSION}/v#{curated_version}/#{@sector}/#{current_month}"

    sector_sym = @sector.to_sym
    @curated_topics = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      slugs = SEASONAL_TOPICS.dig(sector_sym, current_month) ||
              SEASONAL_TOPICS.dig(:common, current_month) || []
      topics = Topic.published.where(slug: slugs).index_by(&:slug)
      # slug 순서 유지 (큐레이션 의도 반영)
      ordered = slugs.filter_map { |s| topics[s] }
      # 6개 미만이면 sector 인기 토픽으로 보충
      if ordered.size < 6
        exclude_ids = ordered.map(&:id)
        filler = Topic.published
                      .where(sector: [:common, @sector])
                      .where.not(id: exclude_ids)
                      .order(view_count: :desc)
                      .limit(6 - ordered.size).to_a
        ordered + filler
      else
        ordered.first(6)
      end
    end

    # sector별 감사사례 (중대/보통 최신 3건)
    @recent_audit_cases = Rails.cache.fetch("home/audit_cases/v#{curated_version}/#{@sector}", expires_in: 1.hour) do
      scope = AuditCase.published.where(severity: %w[중대 보통])
      scope = scope.where(sector: [:common, @sector]) if @sector != "common"
      scope.order(created_at: :desc).limit(3).to_a
    end

    # sector 쿠키 저장 (30일)
    cookies[:sector] = { value: @sector, expires: 30.days, same_site: :lax }

    # 홈페이지는 nav에 인증 상태 포함 → Cloudflare 포함 모든 캐시 금지
    response.headers["Cache-Control"] = "no-store"

    description_text = "공무원을 위한 계약·예산 실무 종합 플랫폼. 수의계약, 적격심사, 입찰, 검수, 예산 편성 등 #{@topic_count}개 현행 법령 가이드와 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 자동화 도구를 무료로 제공합니다. #{@audit_case_count}건 실제 감사사례 분석으로 실수를 예방하고, #{@template_count}종 서식 템플릿으로 업무 시간을 절약하고 안전한 공무를 실현하세요."

    set_meta_tags(
      title: "공무원 계약·예산 실무 가이드 — 수의계약·입찰·여비 법령 안내",
      description: description_text,
      keywords: "공무원, 계약 실무, 수의계약, 입찰, 검수, 예산, 실무 도구",
      canonical: canonical_url,
      og: {
        title: "실무.kr — 공무원 계약 실무 가이드",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def about
    expires_in 1.day, public: true, stale_while_revalidate: 7.days

    topic_count      = Rails.cache.fetch("stats/topic_count", expires_in: 30.minutes) { Topic.published.count }
    guide_count      = Rails.cache.fetch("stats/guide_count", expires_in: 30.minutes) { Guide.published.count }
    audit_case_count = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }
    template_count   = TemplatesController::TEMPLATES.count
    tool_count       = ApplicationHelper::ACTIVE_TOOL_COUNT
    description_text = "실무(silmu.kr)는 공무원의 계약·예산 업무를 돕는 무료 플랫폼입니다. 법령 가이드 #{topic_count}개, 자동화 도구 #{tool_count}개, 감사사례 #{audit_case_count}건, 서식 템플릿 #{template_count}개를 제공하여 복잡한 법령과 절차를 쉽게 이해하고 실무에 바로 적용할 수 있도록 지원합니다."

    set_meta_tags(
      title: "서비스 소개 — 공무원 계약·예산 실무 무료 플랫폼",
      description: description_text,
      canonical: canonical_url,
      og: {
        title: "실무.kr 서비스 소개",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def privacy
    expires_in 1.day, public: true, stale_while_revalidate: 7.days

    description_text = "실무(silmu.kr)의 개인정보처리방침입니다. 개인정보 수집 및 이용 목적, 보유 기간, 제3자 제공, 파기 절차, 이용자 권리 등을 상세히 안내합니다. 문의사항은 hello@silmu.kr로 연락주세요."

    set_meta_tags(
      title: "개인정보처리방침",
      description: description_text,
      canonical: canonical_url,
      og: {
        title: "실무.kr 개인정보처리방침",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def terms
    expires_in 1.day, public: true, stale_while_revalidate: 7.days

    description_text = "실무(silmu.kr) 서비스 이용약관입니다. 서비스 이용 조건, 계정 관리, 콘텐츠 저작권, 면책 조항, 분쟁 해결 등을 명시합니다. 서비스 이용 전 반드시 확인해주세요. 문의: hello@silmu.kr"

    set_meta_tags(
      title: "이용약관",
      description: description_text,
      canonical: canonical_url,
      og: {
        title: "실무.kr 이용약관",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def contact
    expires_in 1.day, public: true, stale_while_revalidate: 7.days

    set_meta_tags(
      title: "문의하기 — 궁금한 점을 남겨주세요",
      description: "실무.kr 운영팀에 문의하세요. 콘텐츠 오류 제보, 기능 건의, 기타 문의사항은 hello@silmu.kr로 보내주시면 2 영업일 내 답변 드립니다.",
      og: {
        title: "문의하기 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      },
      canonical: canonical_url
    )
  end

  def updates
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    set_meta_tags(
      title: "업데이트 소식 — 최신 기능·법령 가이드·감사사례 안내",
      description: "실무.kr의 최신 기능 추가, 콘텐츠 업데이트, 개선 사항을 확인하세요.",
      canonical: canonical_url,
      og: {
        title: "업데이트 소식 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    )
  end

  private

  # sector 결정: URL 파라미터 > 쿠키 > 기본값(common)
  def resolve_sector
    s = params[:sector].presence || cookies[:sector].presence || "common"
    %w[common local_gov edu].include?(s) ? s : "common"
  end
end
