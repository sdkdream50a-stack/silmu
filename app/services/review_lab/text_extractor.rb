# frozen_string_literal: true

require "zip"

module ReviewLab
  # 업로드 바이트 → DocumentArtifact(segments). **결정적 파싱만** 한다 — OCR·외부 AI 없음.
  #
  # 포맷 판정은 브라우저가 보낸 content-type 이나 확장자가 아니라 **바이트**로 한다.
  # «견적서.pdf» 로 이름만 바꾼 HWP 를 PDF 로 믿으면 파서가 빈 결과를 내고,
  # 빈 결과는 화면에서 «문제 없음» 처럼 보인다.
  #
  # 지원하지 않는 것은 지원하지 않는다고 말한다(status: :unsupported + 사람이 할 행동).
  class TextExtractor
    MAX_BYTES = 20.megabytes
    MAX_PDF_PAGES = 60
    MAX_ZIP_ENTRIES = 3_000
    MAX_ENTRY_BYTES = 30.megabytes   # 압축 해제 후 한 엔트리 상한 (zip bomb)
    MAX_SEGMENTS = 5_000
    MAX_SHEETS = 5

    PDF_MAGIC = "%PDF".b
    ZIP_MAGIC = "PK\x03\x04".b
    OLE_MAGIC = "\xD0\xCF\x11\xE0".b   # HWP 5.x · 구형 DOC/XLS 공통 컨테이너
    JPEG_MAGIC = "\xFF\xD8\xFF".b
    PNG_MAGIC = "\x89PNG".b

    UNSUPPORTED = {
      ole: "HWP(한글 97~2022 기본 형식)·구형 DOC/XLS 는 아직 읽지 못합니다. 한글에서 «다른 이름으로 저장 → HWPX» 또는 PDF 로 저장한 뒤 올려 주세요.",
      scanned_pdf: "글자가 없는 PDF(스캔본·사진)입니다. 문자 인식(OCR)은 지원하지 않습니다 — 원본 HWPX·DOCX·XLSX 나 텍스트가 있는 PDF 로 올려 주세요.",
      image: "사진·스캔 이미지는 규칙 검사로 읽을 수 없습니다(문자 인식 미지원). 견적서라면 «AI로 값 읽기»를 선택하거나 원본 파일을 올려 주세요.",
      unknown: "지원하지 않는 파일 형식입니다. PDF(텍스트)·DOCX·XLSX·HWPX 만 올릴 수 있습니다.",
      too_large: "파일이 너무 큽니다(20MB 이하).",
      broken: "파일을 열 수 없습니다(손상되었거나 암호가 걸린 파일일 수 있습니다).",
      empty: "파일에서 글자를 찾지 못했습니다."
    }.freeze

    def self.call(bytes:, role:, label:) = new(bytes: bytes, role: role, label: label).call

    def self.detect_format(bytes)
      b = bytes.to_s.b
      return :pdf if b.start_with?(PDF_MAGIC)
      return :ole if b.start_with?(OLE_MAGIC)
      return :image if b.start_with?(JPEG_MAGIC) || b.start_with?(PNG_MAGIC)
      return zip_format(b) if b.start_with?(ZIP_MAGIC)

      :unknown
    end

    def self.zip_format(bytes)
      # 블록형 open_buffer 는 블록 값이 아니라 Zip::File 을 돌려주고 끝에 버퍼를 다시 쓴다 — 읽기 전용으로만 연다.
      names = Zip::File.open_buffer(StringIO.new(bytes)).entries.first(MAX_ZIP_ENTRIES + 1).map(&:name)
      return :unknown if names.size > MAX_ZIP_ENTRIES
      return :docx if names.include?("word/document.xml")
      return :xlsx if names.include?("xl/workbook.xml")
      return :hwpx if names.any? { |n| n.match?(%r{\AContents/section\d+\.xml\z}) }

      :unknown
    rescue Zip::Error, ArgumentError, IOError
      :broken
    end

    def initialize(bytes:, role:, label:)
      @bytes = bytes.to_s.b
      @role = role
      @label = label
    end

    def call
      return unsupported(:unknown, :too_large) if @bytes.bytesize > MAX_BYTES
      return unsupported(:unknown, :empty) if @bytes.empty?

      format = self.class.detect_format(@bytes)
      case format
      when :pdf  then from_pdf
      when :docx then from_ooxml_or_hwpx(:docx)
      when :hwpx then from_ooxml_or_hwpx(:hwpx)
      when :xlsx then from_xlsx
      when :ole  then unsupported(:ole, :ole)
      when :image then unsupported(:image, :image)
      when :broken then unsupported(:unknown, :broken)
      else unsupported(:unknown, :unknown)
      end
    rescue Zip::Error, Nokogiri::XML::SyntaxError, PDF::Reader::MalformedPDFError,
           PDF::Reader::UnsupportedFeatureError, PDF::Reader::EncryptedPDFError, ArgumentError, IOError
      unsupported(format || :unknown, :broken)
    end

    private

    def artifact(format, segments)
      segments = segments.reject { |s| s[:text].blank? }.first(MAX_SEGMENTS)
      return unsupported(format, format == :pdf ? :scanned_pdf : :empty) if segments.empty?

      DocumentArtifact.new(role: @role, label: @label, format: format, segments: segments)
    end

    def unsupported(format, reason)
      DocumentArtifact.new(role: @role, label: @label, format: format, status: :unsupported, error: UNSUPPORTED.fetch(reason))
    end

    # ── PDF ──────────────────────────────────────────────────────────
    # pdf-reader 는 배치를 공백으로 재현한다. 두 칸 이상 공백을 칸 경계로 보면
    # 표 행을 셀로 나눌 수 있다(확신도는 표 원본보다 낮다 — 호출 측이 locator 로 원문 대조를 안내).
    def from_pdf
      reader = PDF::Reader.new(StringIO.new(@bytes))
      segments = []
      reader.pages.first(MAX_PDF_PAGES).each_with_index do |page, pi|
        page.text.to_s.each_line.with_index do |line, li|
          text = normalize(line)
          next if text.empty?

          parts = line.strip.split(/\s{2,}/).map { |c| normalize(c) }.reject(&:empty?)
          segments << { text: text, locator: "p.#{pi + 1} #{li + 1}행", cells: (parts.size >= 2 ? parts : nil) }
        end
      end
      artifact(:pdf, segments)
    end

    # ── DOCX / HWPX ─────────────────────────────────────────────────
    # 두 포맷 모두 «표 밖 문단» 과 «표 행» 을 문서 순서대로 읽는다.
    # 표 행은 셀 텍스트를 보존한다 — «추정가격 | 45,000,000원» 같은 라벨·값 쌍이 표에 흔하다.
    def from_ooxml_or_hwpx(format)
      docs = zip_xml_entries(format)
      segments = []
      table_no = 0
      docs.each do |doc|
        doc.xpath(node_xpath).each do |node|
          if node.name == "tr"
            cells = node.xpath("./*[local-name()='tc']").map { |tc| normalize(text_of(tc)) }
            table_no += 1 if node.xpath("preceding-sibling::*[local-name()='tr']").empty?
            row_no = node.xpath("preceding-sibling::*[local-name()='tr']").size + 1
            segments << { text: cells.reject(&:empty?).join(" | "), locator: "표 #{table_no} · #{row_no}행", cells: cells }
          else
            text = normalize(own_text(node))
            next if text.empty?

            segments << { text: text, locator: "문단 #{segments.size + 1}", cells: nil }
          end
        end
      end
      artifact(format, segments)
    end

    def node_xpath
      "//*[local-name()='p'][not(ancestor::*[local-name()='tbl'])] | //*[local-name()='tr'][not(ancestor::*[local-name()='tr'])]"
    end

    def text_of(node) = node.xpath(".//*[local-name()='t']").map(&:text).join(" ")

    # 문단 안에 표가 들어 있는 경우(HWPX) 표 글자는 표 행에서 따로 읽으므로 문단 텍스트에서 뺀다.
    def own_text(node) = node.xpath(".//*[local-name()='t'][not(ancestor::*[local-name()='tbl'])]").map(&:text).join

    def zip_xml_entries(format)
      with_zip do |zip|
        names = if format == :docx
          [ "word/document.xml" ]
        else
          zip.entries.map(&:name).grep(%r{\AContents/section\d+\.xml\z}).sort_by { |n| n[/\d+/].to_i }
        end
        names.map { |n| Nokogiri::XML(read_entry(zip, n)) { |c| c.nonet } }
      end
    end

    # ── XLSX ────────────────────────────────────────────────────────
    def from_xlsx
      segments = with_zip do |zip|
        shared = shared_strings(zip)
        sheet_names = zip.entries.map(&:name).grep(%r{\Axl/worksheets/sheet\d+\.xml\z}).sort_by { |n| n[/\d+/].to_i }.first(MAX_SHEETS)
        sheet_names.flat_map.with_index do |name, si|
          doc = Nokogiri::XML(read_entry(zip, name)) { |c| c.nonet }
          doc.xpath("//*[local-name()='row']").map do |row|
            cells = row_cells(row, shared)
            { text: cells.reject(&:empty?).join(" | "), locator: "시트#{si + 1} #{row['r'] || '?'}행", cells: cells }
          end
        end
      end
      artifact(:xlsx, segments)
    end

    def shared_strings(zip)
      entry = zip.find_entry("xl/sharedStrings.xml")
      return [] unless entry

      doc = Nokogiri::XML(read_entry(zip, entry.name)) { |c| c.nonet }
      doc.xpath("//*[local-name()='si']").map { |si| si.xpath(".//*[local-name()='t']").map(&:text).join }
    end

    # 빈 셀이 생략되므로 열 문자(A, B, …)로 제자리에 놓는다 — 안 그러면 «단가» 열이 한 칸씩 밀린다.
    def row_cells(row, shared)
      cells = []
      row.xpath("./*[local-name()='c']").each do |c|
        col = column_index(c["r"].to_s[/\A[A-Z]+/]) || cells.size
        raw = c.at_xpath("./*[local-name()='v']")&.text
        value = case c["t"]
        when "s" then shared[raw.to_i].to_s
        when "inlineStr" then c.xpath(".//*[local-name()='t']").map(&:text).join
        else raw.to_s   # 수식 셀은 캐시된 값(<v>)만 읽는다. 캐시가 없으면 빈 칸 = 모름
        end
        cells[col] = normalize(value)
      end
      cells.map { |v| v.to_s }
    end

    def column_index(letters)
      return nil if letters.blank?

      letters.each_char.reduce(0) { |acc, ch| acc * 26 + (ch.ord - 64) } - 1
    end

    # ── 공통 ───────────────────────────────────────────────────────
    def with_zip
      zip = Zip::File.open_buffer(StringIO.new(@bytes))
      raise Zip::Error, "too many entries" if zip.entries.size > MAX_ZIP_ENTRIES

      yield zip
    end

    # 선언 크기(entry.size)는 조작할 수 있으므로 실제로 읽은 바이트로 상한을 건다.
    def read_entry(zip, name)
      entry = zip.find_entry(name) or raise Zip::Error, "missing #{name}"
      data = entry.get_input_stream { |io| io.read(MAX_ENTRY_BYTES + 1) }.to_s
      raise Zip::Error, "entry too large" if data.bytesize > MAX_ENTRY_BYTES

      data.force_encoding(Encoding::UTF_8)
    end

    def normalize(text)
      text.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
          .tr(" 　", "  ").gsub(/[[:space:]]+/, " ").strip
    end
  end
end
