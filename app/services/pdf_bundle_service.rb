require "prawn"

# Sprint #5-B — 카테고리 묶음 PDF (Tufte + 디지털집현전 모델 권위자)
# silmu의 카테고리별 모든 published 토픽을 1 PDF로 묶어 다운로드 제공.
class PdfBundleService
  FONT_PATH = Rails.root.join("vendor", "fonts", "NanumGothic.ttf")
  FALLBACK_FONT_PATH = "/usr/share/fonts/truetype/nanum/NanumGothic.ttf"

  CATEGORY_LABELS = {
    "contract"  => "계약",
    "budget"    => "예산/결산",
    "expense"   => "지출",
    "salary"    => "급여/수당",
    "subsidy"   => "보조금",
    "property"  => "공유재산",
    "travel"    => "여비/출장",
    "duty"      => "복무",
    "other"     => "기타"
  }.freeze

  class << self
    # 카테고리 묶음 PDF 생성 (Rails.cache 24h)
    # @param category_key [String] 카테고리 key (contract, budget, ...)
    # @return [String, nil] PDF 바이트 또는 nil
    def category_pdf(category_key)
      label = CATEGORY_LABELS[category_key] || category_key
      topics = Topic.published.where(category: category_key).order(:slug).to_a
      return nil if topics.empty?

      latest_at = topics.map(&:updated_at).max.to_i
      cache_key = "category_pdf/v1/#{category_key}/#{latest_at}"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        build_pdf(label, topics)
      end
    end

    private

    def build_pdf(label, topics)
      font_path = font_path_or_fallback
      Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
        if font_path
          pdf.font_families.update(
            "NanumGothic" => { normal: font_path, bold: font_path }
          )
          pdf.font "NanumGothic"
        end

        # 표지
        pdf.font_size(24) { pdf.text "#{label} 분야 법령 가이드", align: :center, style: :bold }
        pdf.move_down 10
        pdf.font_size(11) { pdf.text "silmu.kr — 공무원 실무 법령 가이드", align: :center, color: "555555" }
        pdf.move_down 4
        pdf.font_size(10) do
          pdf.text "수록 토픽 #{topics.size}건 · 생성일 #{Time.zone.today}", align: :center, color: "777777"
        end
        pdf.move_down 30
        pdf.font_size(10) do
          pdf.text "⚠️ 본 자료는 공무원 실무 참고용이며 법률자문이 아닙니다. " \
                   "개별 사안의 법적 판단은 관할 기관·법무담당관·변호사 검토가 필요합니다.",
                   color: "888888", align: :left
        end
        pdf.start_new_page

        # 목차
        pdf.font_size(18) { pdf.text "목차", style: :bold }
        pdf.move_down 8
        topics.each_with_index do |t, i|
          pdf.font_size(11) { pdf.text "#{i + 1}. #{t.name}" }
        end
        pdf.start_new_page

        # 토픽별 본문
        topics.each_with_index do |t, i|
          pdf.font_size(16) { pdf.text "#{i + 1}. #{t.name}", style: :bold }
          pdf.move_down 4
          if t.summary.present?
            pdf.font_size(10) { pdf.text t.summary, color: "555555" }
            pdf.move_down 8
          end
          if t.law_base_date.present?
            pdf.font_size(8) { pdf.text "법령 기준일: #{t.law_base_date}", color: "888888" }
            pdf.move_down 6
          end

          render_section(pdf, "법률", t.law_content)
          render_section(pdf, "시행령", t.decree_content)
          render_section(pdf, "시행규칙", t.rule_content)
          render_section(pdf, "실무 해설", t.commentary)

          if t.faq_list.present?
            pdf.font_size(12) { pdf.text "자주 묻는 질문", style: :bold }
            pdf.move_down 4
            t.faq_list.first(5).each do |faq|
              next unless faq.is_a?(Hash)
              pdf.font_size(10) { pdf.text "Q. #{faq['question']}", style: :bold }
              pdf.font_size(9)  { pdf.text "A. #{faq['answer']}", color: "444444" }
              pdf.move_down 4
            end
          end

          pdf.font_size(8) do
            pdf.fill_color "888888"
            pdf.text "출처: https://silmu.kr/topics/#{t.slug}", align: :right
            pdf.fill_color "000000"
          end
          pdf.start_new_page unless i == topics.size - 1
        end
      end.render
    end

    def render_section(pdf, title, content)
      return if content.blank?
      pdf.font_size(12) { pdf.text title, style: :bold }
      pdf.move_down 2
      plain = ActionController::Base.helpers.strip_tags(content.to_s).gsub(/\s+/, " ").strip
      pdf.font_size(9.5) { pdf.text plain.truncate(2500, separator: " "), align: :justify, leading: 2 }
      pdf.move_down 8
    end

    def font_path_or_fallback
      return FONT_PATH.to_s if File.exist?(FONT_PATH)
      return FALLBACK_FONT_PATH if File.exist?(FALLBACK_FONT_PATH)
      nil
    end
  end
end
