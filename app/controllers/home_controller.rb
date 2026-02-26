class HomeController < ApplicationController
  def index
    @topic_count      = Rails.cache.fetch("stats/topic_count", expires_in: 30.minutes) { Topic.published.count }
    @guide_count      = Rails.cache.fetch("stats/guide_count", expires_in: 30.minutes) { Guide.published.count }
    @audit_case_count = Rails.cache.fetch("stats/audit_case_count", expires_in: 30.minutes) { AuditCase.published.count }
    @template_count   = TemplatesController::TEMPLATES.count

    # HTTP 캐싱: 비로그인 사용자는 5분 캐시, 로그인 사용자는 private
    if user_signed_in?
      expires_in 1.minute, public: false
    else
      expires_in 5.minutes, public: true, stale_while_revalidate: 30.minutes
    end

    description_text = "공무원을 위한 계약·예산 실무 종합 플랫폼. 수의계약, 적격심사, 입찰, 검수, 예산 편성 등 #{@topic_count}개 현행 법령 가이드와 #{ApplicationHelper::ACTIVE_TOOL_COUNT}개 자동화 도구를 무료로 제공합니다. #{@audit_case_count}건 실제 감사사례 분석으로 실수를 예방하고, #{@template_count}종 서식 템플릿으로 업무 시간을 절약하세요."

    set_meta_tags(
      title: "계약 실무, 이제 혼자 고민하지 마세요",
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

    description_text = "실무(silmu.kr)는 공무원의 계약·예산 업무를 돕는 무료 플랫폼입니다. 법령 가이드 37개, 자동화 도구 18개, 감사사례 55건, 서식 템플릿 23개를 제공하여 복잡한 법령과 절차를 쉽게 이해하고 실무에 바로 적용할 수 있도록 지원합니다."

    set_meta_tags(
      title: "서비스 소개 — 공무원 계약·예산 실무 무료 플랫폼",
      description: description_text,
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
      og: {
        title: "실무.kr 이용약관",
        description: description_text,
        url: canonical_url,
        image: "https://silmu.kr/og-image.png",
        type: "website"
      }
    )
  end

  def updates
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    set_meta_tags(
      title: "업데이트 소식 — 최신 기능·법령 가이드·감사사례 안내",
      description: "실무.kr의 최신 기능 추가, 콘텐츠 업데이트, 개선 사항을 확인하세요.",
      og: {
        title: "업데이트 소식 — 실무.kr",
        url: canonical_url,
        image: "https://silmu.kr/og-image.png"
      }
    )
  end
end
