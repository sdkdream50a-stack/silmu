# frozen_string_literal: true

require "test_helper"

# 파일 → 구조화. 포맷은 바이트로 판정하고, 못 읽는 것은 못 읽는다고 말해야 한다.
class ReviewLab::TextExtractorTest < ActiveSupport::TestCase
  B = ReviewLab::FixtureBuilder

  def extract(bytes) = ReviewLab::TextExtractor.call(bytes: bytes, role: "notice", label: "문서")

  test "DOCX 문단과 표 행을 문서 순서대로 읽고 표 칸을 보존한다" do
    doc = extract(B.docx([ "머리말", [ "추정가격", "45,000,000원" ], [ "수량", "12대" ], "끝말" ]))
    assert doc.ok?
    assert_equal :docx, doc.format
    assert_equal [ "머리말", "추정가격 | 45,000,000원", "수량 | 12대", "끝말" ], doc.segments.map { |s| s[:text] }
    assert_equal [ "추정가격", "45,000,000원" ], doc.segments[1][:cells]
    assert_match(/표 1 · 1행/, doc.segments[1][:locator])
  end

  test "HWPX — 문단 안에 든 표도 표 행으로 읽고, 문단 텍스트에 표 글자를 섞지 않는다" do
    doc = extract(B.hwpx([ "공고", [ "공고일", "2026. 10. 5." ] ]))
    assert doc.ok?
    assert_equal :hwpx, doc.format
    assert_equal [ "공고", "공고일 | 2026. 10. 5." ], doc.segments.map { |s| s[:text] }
  end

  test "XLSX — 공유 문자열·inline 문자열·숫자 셀을 모두 읽고 빈 칸 위치를 지킨다" do
    [ true, false ].each do |shared|
      doc = extract(B.xlsx([ [ "품명", "", "수량" ], [ "의자", nil, 30 ] ], shared_strings: shared))
      assert doc.ok?, "shared=#{shared}"
      assert_equal [ "의자", "", "30" ], doc.segments[1][:cells], "shared=#{shared} — 빈 칸이 사라지면 열이 밀린다"
    end
  end

  test "텍스트 PDF 는 쪽·행 위치와 함께 읽는다" do
    doc = extract(B.pdf([ "사업명: 가상 사업", "수량: 10대" ]))
    assert doc.ok?
    assert_equal :pdf, doc.format
    assert(doc.segments.any? { |s| s[:text] == "수량: 10대" && s[:locator].start_with?("p.1") })
  end

  test "HWP(OLE) 는 정직하게 거절하고 HWPX·PDF 변환을 안내한다" do
    doc = extract("\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1".b + ("\x00".b * 600))
    refute doc.ok?
    assert_match(/HWPX/, doc.error)
    assert_empty doc.segments
  end

  test "스캔 PDF(글자 없음)는 «문제 없음» 이 아니라 읽기 실패다" do
    require "prawn"
    blank = Prawn::Document.new { |d| d.stroke_rectangle [ 0, 700 ], 100, 100 }.render
    doc = extract(blank)
    refute doc.ok?
    assert_match(/OCR/, doc.error)
  end

  test "이미지는 규칙 경로에서 읽지 않는다" do
    doc = extract("\x89PNG\r\n\x1A\n".b + "rest".b)
    refute doc.ok?
    assert_match(/문자 인식/, doc.error)
  end

  test "확장자·content-type 이 아니라 바이트로 판정한다 — PDF 로 이름만 바꾼 텍스트는 거절" do
    doc = extract("그냥 텍스트 파일입니다")
    refute doc.ok?
    assert_match(/지원하지 않는/, doc.error)
  end

  test "깨진 ZIP 은 예외가 아니라 읽기 실패로 끝난다" do
    doc = extract("PK\x03\x04".b + "garbage".b * 10)
    refute doc.ok?
  end

  test "zip 해제 크기 상한 — 선언 크기와 무관하게 실제 읽은 바이트로 막는다" do
    big = "<w:document xmlns:w=\"x\"><w:body>" + ("<w:p><w:r><w:t>a</w:t></w:r></w:p>" * 10) + "</w:body></w:document>"
    bytes = B.zip("word/document.xml" => big)
    stub_const(ReviewLab::TextExtractor, :MAX_ENTRY_BYTES, 100) do
      refute extract(bytes).ok?
    end
    assert extract(bytes).ok?, "양성 대조 — 상한 안이면 읽혀야 한다"
  end

  private

  def stub_const(mod, name, value)
    old = mod.const_get(name)
    mod.send(:remove_const, name)
    mod.const_set(name, value)
    yield
  ensure
    mod.send(:remove_const, name)
    mod.const_set(name, old)
  end
end
