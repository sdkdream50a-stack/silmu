class CommunityController < ApplicationController
  def index
    set_meta_tags(
      title: "커뮤니티",
      description: "공무원 계약·예산 실무 담당자들이 경험과 노하우를 나누는 공간입니다.",
      og: { title: "실무 커뮤니티", url: request.original_url }
    )
  end
end
