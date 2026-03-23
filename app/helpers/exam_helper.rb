module ExamHelper
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
