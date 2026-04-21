module ApplicationHelper
  ACTIVE_TOOL_COUNT = 37

  # exam.silmu.kr — 법령 가이드 slug → 한국어 레이블 맵
  # chapters/show.html.erb에서 related_topic_slugs 렌더링 시 사용
  TOPIC_SLUG_LABELS = {
    "public-procurement-overview"   => "공공조달 개요",
    "private-contract"              => "수의계약",
    "bidding"                       => "입찰 절차",
    "bid-qualification"             => "입찰참가자격",
    "e-procurement-guide"           => "전자조달(나라장터)",
    "e-bidding"                     => "전자입찰",
    "mas-contract"                  => "다수공급자계약(MAS)",
    "national-vs-local-contract-law" => "국가·지방계약법 비교",
    "bid-participation-restriction" => "입찰참가자격 제한",
    "estimated-price"               => "예정가격 산정",
    "dual-quote"                    => "2인 견적",
    "qualification-failure"         => "낙찰 실패 처리",
    "price-negotiation"             => "가격협상",
    "contract-guarantee-deposit"    => "계약보증금",
    "lowest-bid-rate"               => "낙찰하한율",
    "contract"                      => "계약 실무",
    "goods-vs-service-contract"     => "물품·용역 계약 구분",
    "goods-selection-committee"     => "물품선정위원회",
    "inspection"                    => "검수·검사",
    "late-penalty"                  => "지체상금",
    "payment"                       => "대금 지급",
    "design-change"                 => "설계변경",
    "contract-termination"          => "계약 해지·해제",
    "unit-price-contract"           => "단가계약",
    "subcontract"                   => "하도급",
    "price-escalation"              => "물가변동(ESC)",
    "defect-warranty"               => "하자보수",
    "budget"                        => "예산 편성",
    "expense"                       => "원가·비용 계산",
    "national-contract-act"         => "국가계약법",
    "contract-management"           => "계약이행 관리"
  }.freeze

  # slug → 한국어 레이블 반환 (없으면 slug 그대로)
  def topic_slug_label(slug)
    TOPIC_SLUG_LABELS[slug] || slug.gsub("-", " ")
  end

  def tool_count
    ACTIVE_TOOL_COUNT
  end

  def utm_params
    session[:utm_params] || {}
  end

  def utm_source
    utm_params[:utm_source] || utm_params["utm_source"]
  end

  def from_naver_blog?
    utm_source == "naver_blog"
  end

  # 현재 페이지에 해당하는 네비게이션 메뉴에 활성 클래스 반환
  def nav_class(section)
    active = case section
    when :guides       then request.path.start_with?("/guides") && !request.path.start_with?("/guides/resources")
    when :topics       then request.path.start_with?("/topics")
    when :audit_cases  then request.path.start_with?("/audit-cases")
    when :tools        then request.path.start_with?("/tools") && !request.path.start_with?("/tools/task-calendar")
    when :task_calendar then request.path.start_with?("/tools/task-calendar")
    when :resources    then request.path.start_with?("/guides/resources")
    when :feedback     then request.path.start_with?("/feedback")
    end
    active ? "nav-link py-2 nav-link-active" : "nav-link py-2"
  end

  # 법령 콘텐츠를 HTML로 변환 (간단한 Markdown 변환)
  # 조, 항, 호 기준으로 줄바꿈하고 가시성 향상
  # 결과를 캐싱하여 무거운 정규식 처리를 반복하지 않음
  def render_legal_content(content)
    return "" if content.blank?

    cache_key = "legal_content/#{Digest::MD5.hexdigest(content)}"
    cached = Rails.cache.read(cache_key)
    return cached.html_safe if cached

    result = LegalContentRenderer.render(content)
    Rails.cache.write(cache_key, result, expires_in: 24.hours)
    result.html_safe
  end

  # 페이지 타입별 OG 이미지 URL 반환
  # 컨트롤러에서 set_og_image(category:)로 @og_image_path가 설정되면 해당 이미지 사용
  # 없으면 기본 이미지 사용
  def og_image_url_for_page
    @og_image_path.presence || "https://silmu.kr/og-image.webp"
  end

  # 간단한 Markdown 변환 (일반 콘텐츠용)
  def simple_markdown(content)
    return "" if content.blank?

    html = sanitize(content, tags: [], attributes: []).dup

    # 제목
    html = html.gsub(/^### (.+)$/, '<h4>\1</h4>')
    html = html.gsub(/^## (.+)$/, '<h3>\1</h3>')

    # 강조
    html = html.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')

    # 목록
    html = html.gsub(/^[-*]\s+(.+)$/, '<li>\1</li>')
    html = html.gsub(/(<li>.*?<\/li>\n?)+/) { |match| "<ul>#{match}</ul>" }

    # 줄바꿈
    html = html.gsub(/\n\n+/, "</p><p>")
    html = html.gsub(/\n/, "<br>")

    "<p>#{html}</p>".html_safe
  end
end
