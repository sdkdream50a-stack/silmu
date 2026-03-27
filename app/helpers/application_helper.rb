module ApplicationHelper
  ACTIVE_TOOL_COUNT = 35

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
    TOPIC_SLUG_LABELS[slug] || slug.gsub('-', ' ')
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
    return '' if content.blank?

    cache_key = "legal_content/#{Digest::MD5.hexdigest(content)}"
    cached = Rails.cache.read(cache_key)
    return cached.html_safe if cached

    result = _render_legal_content_impl(content)
    Rails.cache.write(cache_key, result, expires_in: 24.hours)
    result.html_safe
  end

  def _render_legal_content_impl(content)
    html = sanitize(content, tags: [], attributes: []).dup

    # 1. Markdown 테이블을 HTML 테이블로 변환
    html = convert_markdown_tables(html)

    # 2. 제목 변환 (## -> h3, ### -> h4)
    html = html.gsub(/^### (.+)$/, '<h4 class="legal-h4">\1</h4>')
    html = html.gsub(/^## (.+)$/, '<h3 class="legal-h3">\1</h3>')

    # 2-1. 법령명 표기 (지방계약법, 국가계약법, 시행령, 시행규칙 등)
    html = html.gsub(/^((?:지방|국가)계약법(?:\s*시행(?:령|규칙))?)$/m) do |match|
      "<div class=\"legal-law-name\">#{$1}</div>"
    end

    # 3. 조(條) 표기 - 제X조 형식 (span 사용 - inline 요소 내부에서도 안전)
    html = html.gsub(/(제\d+조(?:의\d+)?)\s*\(([^)]+)\)/) do |match|
      "<span class=\"legal-article\"><span class=\"legal-article-num\">#{$1}</span> <span class=\"legal-article-title\">(#{$2})</span></span>"
    end

    # 4. 항(①②③...) - 줄 시작에서만 매칭 (인라인 §25① 등은 제외)
    html = html.gsub(/(?:^|(?<=\n))([①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮])/) do |match|
      "<div class=\"legal-paragraph\"><span class=\"legal-para-num\">#{$1}</span>"
    end
    # 항 닫기 (다음 항이나 제목 전에) - 인라인 HTML 태그 허용
    html = html.gsub(/(<div class="legal-paragraph"><span class="legal-para-num">[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮]+<\/span>)(.*?)(?=<div class="legal-|<\/div>|<h[34]|\z)/m) do
      "#{$1}<span class=\"legal-para-text\">#{$2.strip}</span></div>"
    end

    # 5. 호(1. 2. 3. ...) - 번호 목록
    html = html.gsub(/^(\d+)\.\s+(.+)$/) do
      "<div class=\"legal-item\"><span class=\"legal-item-num\">#{$1}.</span> <span class=\"legal-item-text\">#{$2}</span></div>"
    end

    # 6. 강조 텍스트 변환 (**텍스트** -> <strong>)
    html = html.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')

    # 7. 밑줄 텍스트 변환 (__텍스트__ -> <u>)
    html = html.gsub(/__([^_]+)__/, '<u>\1</u>')

    # 8. 인용구 (> ...) - 감사사례 등에 사용
    html = html.gsub(/^>\s*(.+)$/, '<div class="legal-blockquote">\1</div>')

    # 8-1. 목록 항목 (- 또는 *)
    html = html.gsub(/^[-*]\s+(.+)$/, '<li class="legal-list-item">\1</li>')
    # 연속된 li를 ul로 감싸기
    html = html.gsub(/(<li class="legal-list-item">.*?<\/li>\n?)+/) do |match|
      "<ul class=\"legal-list\">#{match}</ul>"
    end

    # 9. 빈 줄을 문단 구분으로 (div 사용 - p 안에 div 넣으면 안됨)
    html = html.gsub(/\n\n+/, "</div><div class=\"legal-text\">")

    # 10. 단일 줄바꿈 유지
    html = html.gsub(/\n/, "<br>")

    # 11. 전체를 div 태그로 감싸기 (p 대신 div 사용)
    html = "<div class=\"legal-text\">#{html}</div>"

    html
  end

  # Markdown 테이블을 HTML 테이블로 변환
  def convert_markdown_tables(content)
    lines = content.split("\n")
    result = []
    table_lines = []
    in_table = false

    lines.each do |line|
      if line.strip.start_with?('|') && line.strip.end_with?('|')
        in_table = true
        table_lines << line
      else
        if in_table && table_lines.any?
          result << parse_markdown_table(table_lines)
          table_lines = []
          in_table = false
        end
        result << line
      end
    end

    # 마지막 테이블 처리
    if table_lines.any?
      result << parse_markdown_table(table_lines)
    end

    result.join("\n")
  end

  # Markdown 테이블 파싱
  def parse_markdown_table(lines)
    return '' if lines.empty?

    html = '<div class="legal-table-wrapper"><table class="legal-table">'

    lines.each_with_index do |line, index|
      # 구분선(---|---) 건너뛰기
      next if line.match?(/^\|[\s\-:|]+\|$/)

      cells = line.split('|').map(&:strip).reject(&:empty?)
      tag = index == 0 ? 'th' : 'td'
      row_class = index == 0 ? 'legal-table-header' : 'legal-table-row'

      html += "<tr class=\"#{row_class}\">"
      cells.each do |cell|
        # 강조 텍스트 변환
        cell = cell.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
        html += "<#{tag}>#{cell}</#{tag}>"
      end
      html += '</tr>'
    end

    html += '</table></div>'
    html
  end

  # 간단한 Markdown 변환 (일반 콘텐츠용)
  def simple_markdown(content)
    return '' if content.blank?

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
