# frozen_string_literal: true

# P3 Sprint 2 — OfficialDocumentService 공통표준용어 후처리 안전망
#
# 검증 초점: apply_standard_terms_to_html private 메소드가
#   - HTML 텍스트 노드만 치환하고 style·div 구조는 보존
#   - 빈/비정상 입력에 graceful degradation
#   - StandardTerm 미적재 환경에서도 원본 그대로 통과

require "test_helper"

class OfficialDocumentServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    StandardTerm.expire_synonym_index!
    @service = OfficialDocumentService.new(doc_type: "draft")
  end

  test "HTML 텍스트 노드만 치환, style·div 구조 보존" do
    term = StandardTerm.find_or_create_by!(term_korean: "계약상대자") { |t| t.synonyms = [ "계약 상대자" ] }

    html = <<~HTML.strip
      <div style="font-size:15px;color:#1e293b">
        <span style="font-weight:700">제목:</span> 계약 상대자에게 통보
      </div>
    HTML

    result = @service.send(:apply_standard_terms_to_html, html)

    assert_includes result, "계약상대자"
    refute_includes result, "계약 상대자"
    assert_includes result, 'style="font-size:15px;color:#1e293b"'
    assert_includes result, 'style="font-weight:700"'
  ensure
    term&.destroy
    StandardTerm.expire_synonym_index!
  end

  test "치환 대상 없으면 원본 HTML 그대로 통과" do
    html = '<div style="padding:10px">변경할 단어가 없는 평범한 문장</div>'
    result = @service.send(:apply_standard_terms_to_html, html)

    # Nokogiri 직렬화로 entity 변환 가능 — 핵심 텍스트와 style 보존 확인
    assert_includes result, "변경할 단어가 없는 평범한 문장"
    assert_includes result, "padding:10px"
  end

  test "빈 입력 안전성" do
    assert_equal "", @service.send(:apply_standard_terms_to_html, "")
  end

  test "StandardTerm 미적재 시 원본 그대로 반환 (synonym_index 빈 hash)" do
    html = "<p>계약 상대자에게 통보</p>"
    result = @service.send(:apply_standard_terms_to_html, html)
    assert_includes result, "계약 상대자"
  end

  test "긴 동의어 우선 치환 (greedy match 충돌 방지)" do
    long_term  = StandardTerm.find_or_create_by!(term_korean: "종합심사낙찰제") { |t| t.synonyms = [ "종합 심사 낙찰제" ] }
    short_term = StandardTerm.find_or_create_by!(term_korean: "종합심사") { |t| t.synonyms = [ "종합 심사" ] }

    html = "<p>종합 심사 낙찰제 적용</p>"
    result = @service.send(:apply_standard_terms_to_html, html)

    assert_includes result, "종합심사낙찰제"
    refute_includes result, "종합 심사 낙찰제"
  ensure
    long_term&.destroy
    short_term&.destroy
    StandardTerm.expire_synonym_index!
  end
end
