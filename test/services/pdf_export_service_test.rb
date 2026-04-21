require "test_helper"

class PdfExportServiceTest < ActiveSupport::TestCase
  test "annual_leave_pdf returns nil for invalid hire_date format" do
    assert_nil PdfExportService.annual_leave_pdf(hire_date: "2020/01/01", ref_year: 2026, used_leave: 0)
    assert_nil PdfExportService.annual_leave_pdf(hire_date: "", ref_year: 2026, used_leave: 0)
    assert_nil PdfExportService.annual_leave_pdf(hire_date: nil, ref_year: 2026, used_leave: 0)
    assert_nil PdfExportService.annual_leave_pdf(hire_date: "not-a-date", ref_year: 2026, used_leave: 0)
  end

  test "annual_leave_pdf produces a non-empty PDF byte stream for valid input" do
    pdf_bytes = PdfExportService.annual_leave_pdf(
      hire_date: "2020-03-15",
      ref_year: 2026,
      used_leave: 5,
      monthly_wage: 3_000_000,
      daily_wage: 120_000
    )

    assert pdf_bytes.is_a?(String), "PDF bytes should be a String"
    assert_operator pdf_bytes.bytesize, :>, 1000, "PDF should be meaningfully large"
    # PDF 매직 바이트 %PDF-
    assert pdf_bytes.start_with?("%PDF-"), "output must start with %PDF- signature"
  end

  test "annual_leave_pdf handles same-year hire (prorated granted leave)" do
    # 2026년에 2026년 임용 → 비례처리. 입력 형식 유효하면 PDF 생성 완료 (nil 아님)
    pdf_bytes = PdfExportService.annual_leave_pdf(
      hire_date: "2026-06-01",
      ref_year: 2026,
      used_leave: 0
    )
    refute_nil pdf_bytes
    assert pdf_bytes.start_with?("%PDF-")
  end

  test "annual_leave_pdf handles zero wage inputs" do
    # monthly_wage=0, daily_wage=0 이면 수당/보상 섹션 없이도 정상 생성
    pdf_bytes = PdfExportService.annual_leave_pdf(
      hire_date: "2020-03-15",
      ref_year: 2026,
      used_leave: 3
    )
    refute_nil pdf_bytes
    assert pdf_bytes.start_with?("%PDF-")
  end
end
