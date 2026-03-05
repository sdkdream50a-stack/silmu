require "prawn"

# 실무 도구 PDF 출력 서비스
# 한글 폰트: vendor/fonts/NanumGothic.ttf 필요
#   다운로드: https://fonts.google.com/specimen/Nanum+Gothic
#   또는: sudo apt-get install fonts-nanum  (Ubuntu/Debian)
#          cp /usr/share/fonts/truetype/nanum/NanumGothic.ttf vendor/fonts/
class PdfExportService
  FONT_PATH = Rails.root.join("vendor", "fonts", "NanumGothic.ttf")
  FALLBACK_FONT_PATH = "/usr/share/fonts/truetype/nanum/NanumGothic.ttf"

  class << self
    # 연가 계산 결과 PDF 생성
    # params:
    #   hire_date: String (YYYY-MM-DD)
    #   ref_year: Integer
    #   used_leave: Float
    #   monthly_wage: Integer (선택)
    #   daily_wage: Integer (선택)
    def annual_leave_pdf(params)
      hire_date_str = params[:hire_date].to_s
      ref_year      = params[:ref_year].to_i
      used_leave    = params[:used_leave].to_f
      monthly_wage  = params[:monthly_wage].to_i
      daily_wage    = params[:daily_wage].to_i

      return nil unless hire_date_str.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      hire_date = Date.parse(hire_date_str)
      ref_date  = Date.new(ref_year, 1, 1)
      diff_days = [ (ref_date - hire_date).to_i, 0 ].max
      total_months = (diff_days / 30.44).floor
      years  = total_months / 12
      months = total_months % 12

      leave_info = leave_by_months(total_months)
      granted = leave_info[:days]

      # 신규 임용 연도 비례 처리
      if hire_date.year == ref_year && granted > 0
        remain_months = 12 - hire_date.month + 1
        granted = (granted * remain_months / 12.0).ceil
      end

      remaining = [ granted - used_leave, 0 ].max

      # 통상임금 연차수당 계산 (근로기준법 제60조 제5항)
      ordinary_allowance = nil
      if monthly_wage > 0 && remaining > 0
        daily_ordinary = monthly_wage / 209.0
        ordinary_allowance = {
          daily_ordinary: daily_ordinary.round,
          total: (daily_ordinary * remaining).round,
          days: remaining
        }
      end

      # 연가보상비 계산 (최대 20일)
      compensation = nil
      if daily_wage > 0 && remaining > 0
        comp_days = [ remaining, 20 ].min
        compensation = { days: comp_days, total: (daily_wage * comp_days).round }
      end

      build_annual_leave_pdf(
        hire_date: hire_date,
        ref_year: ref_year,
        years: years,
        months: months,
        granted: granted,
        used_leave: used_leave,
        remaining: remaining,
        leave_label: leave_info[:label],
        ordinary_allowance: ordinary_allowance,
        compensation: compensation,
        monthly_wage: monthly_wage,
        daily_wage: daily_wage
      )
    end

    private

    def leave_by_months(total_months)
      return { days: 0, label: "1개월 미만 - 연가 없음" } if total_months < 1
      return { days: 11, label: "1개월 이상 ~ 1년 미만 -> 11일" } if total_months < 12
      years = total_months / 12
      return { days: 12, label: "1년 이상 ~ 2년 미만 -> 12일" } if years < 2
      return { days: 14, label: "2년 이상 ~ 3년 미만 -> 14일" } if years < 3
      return { days: 15, label: "3년 이상 ~ 4년 미만 -> 15일" } if years < 4
      return { days: 17, label: "4년 이상 ~ 5년 미만 -> 17일" } if years < 5
      return { days: 20, label: "5년 이상 ~ 6년 미만 -> 20일" } if years < 6
      { days: 21, label: "6년 이상 -> 21일" }
    end

    def font_available?
      File.exist?(FONT_PATH) || File.exist?(FALLBACK_FONT_PATH)
    end

    def font_file
      File.exist?(FONT_PATH) ? FONT_PATH.to_s : FALLBACK_FONT_PATH
    end

    def build_annual_leave_pdf(data)
      Prawn::Document.new(
        page_size: "A4",
        margin: [ 50, 50, 50, 50 ],
        info: {
          Title: "연가일수 계산 결과",
          Creator: "silmu.kr",
          CreationDate: Time.current
        }
      ) do |pdf|
        setup_fonts(pdf)

        # 제목 영역
        pdf.fill_color "4338ca"
        pdf.fill_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 60
        pdf.fill_color "ffffff"
        pdf.text_box "연가일수 계산 결과",
          at: [ 10, pdf.cursor - 12 ], width: pdf.bounds.width - 20,
          size: 20, style: :bold, valign: :center, height: 36

        pdf.fill_color "000000"
        pdf.move_down 70

        # 발급 정보
        pdf.fill_color "64748b"
        pdf.text "발급일시: #{Time.zone.now.strftime('%Y년 %m월 %d일 %H:%M')}  |  출처: silmu.kr",
          size: 9, align: :right
        pdf.fill_color "000000"
        pdf.move_down 10

        # 구분선
        pdf.stroke_color "e2e8f0"
        pdf.stroke_horizontal_rule
        pdf.move_down 15

        # 재직 기간 요약
        period_text = []
        period_text << "#{data[:years]}년" if data[:years] > 0
        period_text << "#{data[:months]}개월" if data[:months] > 0
        period_text = period_text.empty? ? "1개월 미만" : period_text.join(" ")

        section_header(pdf, "재직 기간 및 연가 현황")
        info_table(pdf, [
          [ "최초 임용일", data[:hire_date].strftime("%Y년 %m월 %d일") ],
          [ "기준 연도", "#{data[:ref_year]}년 (1월 1일 기준)" ],
          [ "재직 기간", period_text ],
          [ "적용 기준", data[:leave_label] ]
        ])
        pdf.move_down 15

        # 연가 현황 카드
        section_header(pdf, "연가 현황")
        leave_table(pdf, [
          [ "부여 연가", "#{data[:granted].to_i}일", "4338ca" ],
          [ "사용 연가", "#{data[:used_leave].to_i}일", "dc2626" ],
          [ "잔여 연가", "#{data[:remaining].to_i}일", "059669" ]
        ])
        pdf.move_down 15

        # 연차수당 (통상임금 기준)
        if data[:ordinary_allowance]
          oa = data[:ordinary_allowance]
          section_header(pdf, "연차수당 (통상임금 기준)")
          pdf.fill_color "eff6ff"
          pdf.fill_rounded_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 80, 6
          pdf.fill_color "000000"
          pdf.bounding_box([ 10, pdf.cursor - 5 ], width: pdf.bounds.width - 20) do
            pdf.text "1일 통상임금: #{fmt_currency(data[:monthly_wage])}원 / 209시간 = #{fmt_currency(oa[:daily_ordinary])}원",
              size: 11
            pdf.move_down 5
            pdf.text "연차수당 합계: #{fmt_currency(oa[:daily_ordinary])}원 x #{oa[:days].to_i}일 = #{fmt_currency(oa[:total])}원",
              size: 13, style: :bold
            pdf.move_down 5
            pdf.fill_color "6366f1"
            pdf.text "(근거: 근로기준법 제60조 제5항)", size: 9
            pdf.fill_color "000000"
          end
          pdf.move_down 90
        end

        # 연가보상비 (일급 기준)
        if data[:compensation]
          comp = data[:compensation]
          section_header(pdf, "미사용 연가보상비 (최대 20일 한도)")
          pdf.fill_color "fffbeb"
          pdf.fill_rounded_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 65, 6
          pdf.fill_color "000000"
          pdf.bounding_box([ 10, pdf.cursor - 5 ], width: pdf.bounds.width - 20) do
            pdf.text "일급여액: #{fmt_currency(data[:daily_wage])}원 x #{comp[:days].to_i}일 (최대 20일) = #{fmt_currency(comp[:total])}원",
              size: 12, style: :bold
          end
          pdf.move_down 75
        end

        # 법적 근거
        pdf.stroke_color "e2e8f0"
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        section_header(pdf, "법적 근거")
        pdf.fill_color "374151"
        pdf.text "• 연가일수 기준: 국가공무원 복무규정 제15조, 지방공무원 복무규정 제7조", size: 9
        pdf.text "• 연차수당 기준: 근로기준법 제60조 제5항 (1일 통상임금 = 월급 / 209시간)", size: 9
        pdf.text "• 연가보상비: 국가공무원 복무규정 제21조의2 (최대 20일 한도)", size: 9
        pdf.fill_color "000000"
        pdf.move_down 10

        # 면책 고지
        pdf.fill_color "9ca3af"
        pdf.text "본 계산 결과는 참고용이며, 정확한 연가 산정은 소속 기관의 인사부서에 확인하시기 바랍니다.", size: 8
        pdf.fill_color "000000"
      end.render
    end

    def setup_fonts(pdf)
      if font_available?
        pdf.font_families.update(
          "Korean" => { normal: font_file, bold: font_file }
        )
        pdf.font "Korean"
      end
      pdf.font_size 11
    end

    def section_header(pdf, text)
      pdf.fill_color "1e293b"
      pdf.text text, size: 13, style: :bold
      pdf.move_down 6
    end

    def info_table(pdf, rows)
      rows.each do |label, value|
        pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width) do
          pdf.fill_color "f8fafc"
          pdf.fill_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 22
          pdf.fill_color "64748b"
          pdf.text_box label, at: [ 8, pdf.cursor - 5 ], width: 150, height: 16, size: 10
          pdf.fill_color "1e293b"
          pdf.text_box value, at: [ 165, pdf.cursor - 5 ], width: pdf.bounds.width - 170, height: 16, size: 10, style: :bold
          pdf.fill_color "000000"
          pdf.move_down 24
        end
      end
    end

    def leave_table(pdf, rows)
      col_width = (pdf.bounds.width - 20) / 3
      pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width) do
        rows.each_with_index do |(label, value, color), i|
          x = i * (col_width + 10)
          pdf.fill_color "f8fafc"
          pdf.fill_rounded_rectangle [ x, pdf.cursor ], col_width, 60, 6
          pdf.fill_color color
          pdf.text_box label, at: [ x + 8, pdf.cursor - 8 ], width: col_width - 16, height: 16, size: 10, align: :center
          pdf.text_box value, at: [ x + 8, pdf.cursor - 28 ], width: col_width - 16, height: 28, size: 20, style: :bold, align: :center
          pdf.fill_color "000000"
        end
        pdf.move_down 65
      end
    end

    def fmt_currency(amount)
      amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
