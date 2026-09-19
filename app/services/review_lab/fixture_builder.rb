# frozen_string_literal: true

require "zip"

module ReviewLab
  # 연수 demo·테스트용 **가상 문서**를 바이트로 만든다(DOCX·XLSX·HWPX·PDF).
  #
  # 왜 파일을 저장소에 넣지 않고 코드로 만드는가
  #   · demo 가 텍스트를 바로 검사기에 넣으면 «파일을 읽는 부분» 을 건너뛴다. 연수에서 보여주는 것이
  #     실제 업로드 경로와 같아야 한다 — 그래서 진짜 파일 바이트를 만들어 TextExtractor 부터 통과시킨다.
  #   · 내용이 코드에 있으니 Expected Findings 와 같은 곳에서 리뷰된다.
  #
  # 만드는 파일은 파서가 읽는 최소 구조다. HWPX 는 한글 프로그램이 여는 완전한 패키지가 아니다.
  module FixtureBuilder
    module_function

    # rows: [[셀, …] 또는 "문단"] — 배열이면 표 행, 문자열이면 문단. 연속된 배열 행은 한 표로 묶는다.
    def docx(blocks)
      body = group(blocks).map do |b|
        if b.is_a?(String)
          %(<w:p><w:r><w:t xml:space="preserve">#{esc(b)}</w:t></w:r></w:p>)
        else
          rows = b.map { |r| "<w:tr>" + r.map { |c| %(<w:tc><w:p><w:r><w:t xml:space="preserve">#{esc(c)}</w:t></w:r></w:p></w:tc>) }.join + "</w:tr>" }.join
          "<w:tbl>#{rows}</w:tbl>"
        end
      end.join
      zip(
        "[Content_Types].xml" => %(<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>),
        "_rels/.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>),
        "word/document.xml" => %(<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>#{body}</w:body></w:document>)
      )
    end

    # rows: [[셀, …]] — 숫자는 숫자 셀, 나머지는 공유 문자열(shared_strings: true) 또는 inline 문자열.
    def xlsx(rows, shared_strings: true)
      strings = []
      sheet_rows = rows.each_with_index.map do |row, ri|
        cells = row.each_with_index.filter_map do |v, ci|
          next if v.nil? || v == ""

          ref = "#{col(ci)}#{ri + 1}"
          if v.is_a?(Numeric)
            %(<c r="#{ref}"><v>#{v}</v></c>)
          elsif shared_strings
            idx = strings.index(v.to_s) || (strings << v.to_s).size - 1
            %(<c r="#{ref}" t="s"><v>#{idx}</v></c>)
          else
            %(<c r="#{ref}" t="inlineStr"><is><t>#{esc(v)}</t></is></c>)
          end
        end
        %(<row r="#{ri + 1}">#{cells.join}</row>)
      end
      files = {
        "[Content_Types].xml" => %(<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>#{shared_strings ? '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' : ''}</Types>),
        "_rels/.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>),
        "xl/workbook.xml" => %(<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="견적서" sheetId="1" r:id="rId1"/></sheets></workbook>),
        "xl/_rels/workbook.xml.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>#{shared_strings ? '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>' : ''}</Relationships>),
        "xl/worksheets/sheet1.xml" => %(<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>#{sheet_rows.join}</sheetData></worksheet>)
      }
      if shared_strings
        files["xl/sharedStrings.xml"] = %(<?xml version="1.0" encoding="UTF-8"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="#{strings.size}" uniqueCount="#{strings.size}">#{strings.map { |s| "<si><t>#{esc(s)}</t></si>" }.join}</sst>)
      end
      zip(files)
    end

    HP = "http://www.hancom.co.kr/hwpml/2011/paragraph"

    def hwpx(blocks)
      body = group(blocks).map do |b|
        if b.is_a?(String)
          %(<hp:p><hp:run><hp:t>#{esc(b)}</hp:t></hp:run></hp:p>)
        else
          rows = b.map { |r| "<hp:tr>" + r.map { |c| %(<hp:tc><hp:subList><hp:p><hp:run><hp:t>#{esc(c)}</hp:t></hp:run></hp:p></hp:subList></hp:tc>) }.join + "</hp:tr>" }.join
          # 한글은 표를 문단 안(run 안)에 넣는다 — 파서가 그 구조를 견디는지도 함께 확인한다.
          %(<hp:p><hp:run><hp:tbl>#{rows}</hp:tbl></hp:run></hp:p>)
        end
      end.join
      zip(
        "mimetype" => "application/hwp+zip",
        "Contents/section0.xml" => %(<?xml version="1.0" encoding="UTF-8"?><hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section" xmlns:hp="#{HP}">#{body}</hs:sec>)
      )
    end

    FONT = Rails.root.join("vendor", "fonts", "NanumGothic.ttf")

    # lines: ["문단"] 또는 [[셀, …]] — 표 행은 고정 x 좌표에 칸을 찍는다(pdf-reader 가 공백으로 칸을 재현).
    def pdf(lines, columns: nil)
      require "prawn"
      Prawn::Document.new(page_size: "A4", margin: 40) do |d|
        d.font(FONT.to_s)
        d.font_size 9
        lines.each do |line|
          if line.is_a?(Array)
            xs = columns || line.each_index.map { |i| i * 80 }
            y = d.cursor
            line.each_with_index { |c, i| d.draw_text(c.to_s, at: [ xs[i], y - 10 ]) unless c.to_s.empty? }
            d.move_down 16
          else
            d.text line.to_s
            d.move_down 4
          end
        end
      end.render
    end

    def group(blocks)
      blocks.chunk_while { |a, b| a.is_a?(Array) && b.is_a?(Array) }.map { |g| g.first.is_a?(Array) ? g : g.first }
    end

    def zip(files)
      io = Zip::OutputStream.write_buffer(StringIO.new) do |z|
        files.each do |name, content|
          z.put_next_entry(name)
          z.write(content)
        end
      end
      io.string
    end

    def esc(s) = ERB::Util.html_escape(s.to_s)

    def col(i)
      s = +""
      i += 1
      while i.positive?
        i, r = (i - 1).divmod(26)
        s.prepend((65 + r).chr)
      end
      s
    end
  end
end
