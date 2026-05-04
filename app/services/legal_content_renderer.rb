class LegalContentRenderer
  # 법령 콘텐츠를 HTML로 변환
  # 조, 항, 호 기준으로 줄바꿈하고 가시성 향상
  def self.render(content)
    new(content).render
  end

  def initialize(content)
    @content = content
  end

  def render
    html = ActionController::Base.helpers.sanitize(@content, tags: [], attributes: []).dup

    # 1. Markdown 테이블을 HTML 테이블로 변환
    html = convert_markdown_tables(html)

    # 2. 제목 변환 — 접근성: h2(카드 헤더) 직후 h4 점프를 피하기 위해 둘 다 h3로 내보냄.
    # WCAG 1.3.1 위반 방지. 시각 위계는 CSS class(legal-h3/legal-h4)가 유지.
    html = html.gsub(/^### (.+)$/, '<h3 class="legal-h4">\1</h3>')
    html = html.gsub(/^## (.+)$/, '<h3 class="legal-h3">\1</h3>')

    # 2-1. 법령명 표기 (지방계약법, 국가계약법, 시행령, 시행규칙 등)
    html = html.gsub(/^((?:지방|국가)계약법(?:\s*시행(?:령|규칙))?)$/m) do |match|
      "<div class=\"legal-law-name\">#{$1}</div>"
    end

    # 3. 조(條) 표기 - 제X조 형식 (cite 태그 — HTML5 시맨틱 + AEO/GEO 추출 정확도 향상)
    html = html.gsub(/(제\d+조(?:의\d+)?)\s*\(([^)]+)\)/) do |match|
      "<cite class=\"legal-article\"><span class=\"legal-article-num\">#{$1}</span> <span class=\"legal-article-title\">(#{$2})</span></cite>"
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
    "<div class=\"legal-text\">#{html}</div>"
  end

  private

  # Markdown 테이블을 HTML 테이블로 변환
  def convert_markdown_tables(content)
    lines = content.split("\n")
    result = []
    table_lines = []
    in_table = false

    lines.each do |line|
      if line.strip.start_with?("|") && line.strip.end_with?("|")
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
    result << parse_markdown_table(table_lines) if table_lines.any?

    result.join("\n")
  end

  # Markdown 테이블 파싱
  def parse_markdown_table(lines)
    return "" if lines.empty?

    html = '<div class="legal-table-wrapper"><table class="legal-table">'

    lines.each_with_index do |line, index|
      # 구분선(---|---) 건너뛰기
      next if line.match?(/^\|[\s\-:|]+\|$/)

      cells = line.split("|").map(&:strip).reject(&:empty?)
      tag = index == 0 ? "th" : "td"
      row_class = index == 0 ? "legal-table-header" : "legal-table-row"

      html += "<tr class=\"#{row_class}\">"
      cells.each do |cell|
        # 강조 텍스트 변환
        cell = cell.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
        html += "<#{tag}>#{cell}</#{tag}>"
      end
      html += "</tr>"
    end

    html += "</table></div>"
    html
  end
end
