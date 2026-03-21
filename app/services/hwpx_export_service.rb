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

  # 수의계약 사유서 HWPX 생성
  def self.generate_contract_reason(params)
    call_generator(
      mode:            "contract_reason",
      contract_name:   params[:contract_name].to_s.truncate(100, omission: ""),
      type_label:      params[:type_label].to_s,
      budget:          params[:budget].to_s,
      budget_korean:   params[:budget_korean].to_s,
      vat_label:       params[:vat_label].to_s,
      company:         params[:company].to_s,
      business_no:     params[:business_no].to_s,
      delivery:        params[:delivery].to_s,
      reason_detail:   params[:reason_detail].to_s,
      reason_law:      params[:reason_law].to_s,
      reason_law_text: params[:reason_law_text].to_s,
      background:      params[:background].to_s,
      dept:            params[:dept].to_s.presence || "○○과",
      manager:         params[:manager].to_s,
      date_str:        Time.zone.today.strftime("%Y. %-m. %-d.")
    )
  end

  # 사업계획서 HWPX 생성
  def self.generate_project_plan(params)
    call_generator(
      mode:           "project_plan",
      project_name:   params[:project_name].to_s.truncate(100, omission: ""),
      department:     params[:department].to_s.presence || "○○과",
      manager:        params[:manager].to_s,
      contact:        params[:contact].to_s,
      necessity:      params[:necessity].to_s,
      current_status: params[:current_status].to_s,
      content:        params[:content].to_s,
      schedule:       params[:schedule].to_s,
      budget:         params[:budget].to_s,
      budget_korean:  params[:budget_korean].to_s,
      budget_item:    params[:budget_item].to_s,
      effect:         params[:effect].to_s,
      date_str:       Time.zone.today.strftime("%Y. %-m. %-d.")
    )
  end

  # 연가 계산 결과 HWPX 생성
  def self.generate_annual_leave(params)
    call_generator(
      mode:                    "annual_leave",
      hire_date:               params[:hire_date].to_s,
      ref_year:                params[:ref_year].to_s,
      service_period:          params[:service_period].to_s,
      granted_leave:           params[:granted_leave].to_s,
      used_leave:              params[:used_leave].to_s,
      remaining_leave:         params[:remaining_leave].to_s,
      annual_allowance_pay:    params[:annual_allowance_pay].to_s,
      annual_allowance_detail: params[:annual_allowance_detail].to_s,
      compensation_pay:        params[:compensation_pay].to_s,
      compensation_detail:     params[:compensation_detail].to_s,
      date_str:                Time.zone.today.strftime("%Y. %-m. %-d.")
    )
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
