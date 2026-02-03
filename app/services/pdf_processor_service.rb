require "combine_pdf"
require "prawn"
require "pdf-reader"
require "zip"

class PdfProcessorService
  class << self
    # PDF 분할
    def split(file, ranges: nil)
      pdf = CombinePDF.parse(file.read)
      total_pages = pdf.pages.count

      # 범위 파싱
      page_ranges = parse_ranges(ranges, total_pages)

      if page_ranges.empty?
        raise "유효한 페이지 범위를 입력해주세요."
      end

      files = []

      page_ranges.each_with_index do |range, index|
        new_pdf = CombinePDF.new
        range.each do |page_num|
          new_pdf << pdf.pages[page_num - 1] if pdf.pages[page_num - 1]
        end

        filename = if page_ranges.length == 1
                     "split_#{range.first}-#{range.last}.pdf"
                   else
                     "split_part#{index + 1}_#{range.first}-#{range.last}.pdf"
                   end

        files << {
          name: filename,
          data: new_pdf.to_pdf
        }
      end

      result = { files: files }

      # 여러 파일일 경우 ZIP 생성
      if files.length > 1
        result[:zip_data] = create_zip(files)
      end

      result
    end

    # PDF 합치기
    def merge(files)
      merged_pdf = CombinePDF.new

      files.each do |file|
        pdf = CombinePDF.parse(file.read)
        merged_pdf << pdf
      end

      {
        name: "merged_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf",
        data: merged_pdf.to_pdf
      }
    end

    # 페이지 번호 추가
    def add_page_numbers(file, options = {})
      position = options[:position] || "bottom_center"
      start_number = options[:start_number] || 1
      format = options[:format] || "number"
      font_size = options[:font_size] || 10
      skip_first = options[:skip_first] || false

      # 원본 PDF 읽기
      original_pdf = CombinePDF.parse(file.read)
      total_pages = original_pdf.pages.count

      # 각 페이지에 번호 추가
      original_pdf.pages.each_with_index do |page, index|
        next if skip_first && index == 0

        page_num = start_number + (skip_first ? index - 1 : index)
        page_num = start_number + index unless skip_first

        # 페이지 번호 포맷
        number_text = format_page_number(page_num, total_pages, format)

        # Prawn으로 페이지 번호 오버레이 생성
        number_pdf = create_page_number_overlay(
          page,
          number_text,
          position,
          font_size
        )

        # 오버레이 합성
        page << CombinePDF.parse(number_pdf).pages.first
      end

      {
        name: "numbered_#{file.original_filename}",
        data: original_pdf.to_pdf
      }
    end

    # PDF 정보 조회
    def get_info(file)
      pdf = CombinePDF.parse(file.read)

      # PDF Reader로 상세 정보
      file.rewind
      reader = PDF::Reader.new(file)

      {
        page_count: pdf.pages.count,
        title: reader.info[:Title],
        author: reader.info[:Author],
        creator: reader.info[:Creator],
        producer: reader.info[:Producer],
        creation_date: reader.info[:CreationDate],
        file_size: file.size,
        file_name: file.original_filename
      }
    rescue => e
      {
        page_count: pdf.pages.count,
        file_name: file.original_filename,
        file_size: file.size,
        error: "일부 정보를 읽을 수 없습니다."
      }
    end

    private

    # 페이지 범위 파싱 (예: "1-3,5,7-10")
    def parse_ranges(ranges_str, total_pages)
      return [[1, total_pages]] if ranges_str.blank?

      result = []

      ranges_str.split(",").each do |part|
        part = part.strip

        if part.include?("-")
          start_page, end_page = part.split("-").map(&:to_i)
          start_page = [1, start_page].max
          end_page = [end_page, total_pages].min
          result << (start_page..end_page).to_a if start_page <= end_page
        else
          page = part.to_i
          result << [page] if page >= 1 && page <= total_pages
        end
      end

      result
    end

    # 페이지 번호 포맷
    def format_page_number(current, total, format)
      case format
      when "dash"
        "- #{current} -"
      when "parenthesis"
        "(#{current})"
      when "of_total"
        "#{current} / #{total}"
      when "page_of"
        "#{current}페이지 / #{total}페이지"
      else
        current.to_s
      end
    end

    # 페이지 번호 오버레이 PDF 생성
    def create_page_number_overlay(page, number_text, position, font_size)
      # 페이지 크기 추출
      page_width = 595.28  # A4 기본
      page_height = 841.89

      if page[:MediaBox]
        page_width = page[:MediaBox][2] - page[:MediaBox][0]
        page_height = page[:MediaBox][3] - page[:MediaBox][1]
      end

      # 위치 계산
      x, y = calculate_position(position, page_width, page_height, font_size)

      Prawn::Document.new(
        page_size: [page_width, page_height],
        margin: 0
      ) do |pdf|
        pdf.font_size(font_size)
        pdf.fill_color "000000"

        # 텍스트 폭 계산
        text_width = pdf.width_of(number_text)

        # 위치 조정 (가운데 정렬용)
        adjusted_x = case position
                     when /center/
                       x - (text_width / 2)
                     when /right/
                       x - text_width
                     else
                       x
                     end

        pdf.draw_text number_text, at: [adjusted_x, y]
      end.render
    end

    # 위치 계산
    def calculate_position(position, width, height, font_size)
      margin = 30

      case position
      when "top_left"
        [margin, height - margin]
      when "top_center"
        [width / 2, height - margin]
      when "top_right"
        [width - margin, height - margin]
      when "bottom_left"
        [margin, margin]
      when "bottom_center"
        [width / 2, margin]
      when "bottom_right"
        [width - margin, margin]
      else
        [width / 2, margin] # 기본: 하단 중앙
      end
    end

    # ZIP 파일 생성
    def create_zip(files)
      Zip::OutputStream.write_buffer do |zip|
        files.each do |file|
          zip.put_next_entry(file[:name])
          zip.write(file[:data])
        end
      end.string
    end
  end
end
