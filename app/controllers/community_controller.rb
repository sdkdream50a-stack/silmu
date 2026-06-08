class CommunityController < ApplicationController
  def index
    # 정적 콘텐츠이므로 HTTP 캐싱
    expires_in 1.hour, public: true, stale_while_revalidate: 1.day

    set_meta_tags(
      title: "커뮤니티",
      description: "공무원 계약·예산 실무 담당자들이 현장 경험과 노하우를 나누는 공간입니다. 수의계약·입찰·감사 대응 등 실무에서 마주치는 고민을 함께 풀어보세요.",
      og: { title: "실무.kr 커뮤니티", url: canonical_url }
    )
  end
end
