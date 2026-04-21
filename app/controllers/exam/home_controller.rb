class Exam::HomeController < ApplicationController
  layout "exam"

  def index
    # 정적 콘텐츠이므로 HTTP 캐싱
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    set_meta_tags(
      title: "공공조달관리사 시험 대비",
      description: "2026년 신설 공공조달관리사 국가기술자격시험을 체계적으로 준비하세요. 표준교재 4권 27장 전 범위 핵심 내용 정리, 현행 법령 조문 해설, 155건 감사사례 분석, 29개 자동화 도구를 무료 제공합니다. 공무원·공공기관 종사자를 위한 기출 유형 분석과 암기법을 한 곳에서 완성하세요.",
      keywords: "공공조달관리사, 국가기술자격시험, 공공조달, 계약 실무, 시험 대비, 2026, 법령 정리",
      canonical: "https://exam.silmu.kr",
      og: {
        title: "공공조달관리사 시험 대비 | 실무.kr",
        description: "2026년 신설 공공조달관리사 국가기술자격시험을 체계적으로 준비하세요. 표준교재 4권 27장 전 범위 핵심 내용 정리, 현행 법령 조문 해설, 155건 감사사례 분석, 29개 자동화 도구를 무료 제공합니다. 공무원·공공기관 종사자를 위한 기출 유형 분석과 암기법을 한 곳에서 완성하세요.",
        url: "https://exam.silmu.kr",
        type: "website",
        image: "https://exam.silmu.kr/icon.png"
      },
      twitter: {
        card: "summary",
        title: "공공조달관리사 시험 대비 | 실무.kr",
        description: "2026년 신설 공공조달관리사 국가기술자격시험을 체계적으로 준비하세요. 표준교재 4권 27장 전 범위 핵심 내용 정리, 현행 법령 조문 해설, 155건 감사사례 분석, 29개 자동화 도구를 무료 제공합니다. 공무원·공공기관 종사자를 위한 기출 유형 분석과 암기법을 한 곳에서 완성하세요.",
        image: "https://exam.silmu.kr/icon.png"
      }
    )
  end
end
