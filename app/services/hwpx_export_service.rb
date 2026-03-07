require "open3"
require "tempfile"
require "json"

# HWPX(한글) 파일 생성 서비스
# python-hwpx 라이브러리를 Python 서브프로세스로 호출합니다.
# Docker 이미지에 /opt/hwpx-venv Python venv가 설치되어 있어야 합니다.
class HwpxExportService
  PYTHON_BIN = ENV.fetch("HWPX_PYTHON_BIN", "/opt/hwpx-venv/bin/python3")
  SCRIPT_PATH = Rails.root.join("lib", "hwpx_generator.py").to_s

  # 감사사례 HWPX 생성
  # @return [String, nil] HWPX 파일의 binary 데이터, 실패 시 nil
  def self.generate_audit_case(audit_case)
    checkpoints = begin
      JSON.parse(audit_case.checkpoints.to_s)
    rescue
      []
    end

    data = {
      mode: "audit_case",
      title: audit_case.title,
      category: audit_case.category,
      severity: audit_case.severity,
      legal_basis: audit_case.legal_basis,
      issue: audit_case.issue,
      lesson: audit_case.lesson,
      checkpoints: checkpoints
    }

    call_generator(data)
  end

  # 공문서 HWPX 생성
  # @return [String, nil] HWPX 파일의 binary 데이터, 실패 시 nil
  def self.generate_official_document(title:, doc_type_label:, content:)
    data = {
      mode: "official_document",
      title: title,
      doc_type_label: doc_type_label,
      content: content
    }

    call_generator(data)
  end

  private

  def self.call_generator(data)
    tmpfile = Tempfile.new([ "hwpx_", ".hwpx" ])
    tmpfile.close

    data[:output_path] = tmpfile.path

    stdout, stderr, status = Open3.capture3(
      PYTHON_BIN, SCRIPT_PATH,
      stdin_data: data.to_json
    )

    unless status.success?
      Rails.logger.error "HwpxExportService error: #{stderr.strip}"
      tmpfile.unlink
      return nil
    end

    binary = File.binread(tmpfile.path)
    tmpfile.unlink
    binary
  rescue => e
    Rails.logger.error "HwpxExportService exception: #{e.message}"
    tmpfile&.unlink
    nil
  end
end
