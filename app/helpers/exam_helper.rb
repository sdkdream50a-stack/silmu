module ExamHelper
  # 콘텐츠 성격 라벨 (2026-09-17 전수감사 G-15 D-1).
  # 공식 사실·표준교재 요약·자체 문항·예측이 화면에서 같은 무게로 읽히지 않게 구분한다.
  CONTENT_BADGES = {
    official: "공식 · 큐넷",
    textbook: "표준교재 요약",
    practice: "실무.kr 자체 문항",
    prediction: "실무.kr 예측"
  }.freeze

  def content_badge(kind)
    content_tag(:span, CONTENT_BADGES.fetch(kind),
                class: "inline-flex items-center rounded-full border border-slate-200 bg-white px-2.5 py-0.5 text-xs font-semibold text-slate-700 align-middle",
                data: { content_badge: kind })
  end

  # theory_content의 content/points 문자열에서 마크다운 마커를 HTML로 변환
  #   **텍스트** → <strong> 진한 글씨 (시험 핵심어/수치)
  #   ==텍스트== → <mark>  형광펜 효과 (절대 암기 필수 문장)
  def format_theory_text(text)
    return "".html_safe if text.blank?

    html = CGI.escapeHTML(text.to_s)
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong class="font-bold text-slate-900">\1</strong>')
    html = html.gsub(/==(.+?)==/, '<mark class="bg-yellow-200 px-0.5 rounded">\1</mark>')
    html.html_safe
  end
end
