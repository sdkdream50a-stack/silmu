# frozen_string_literal: true

require "test_helper"

class BlogLegalVerifierTest < ActiveSupport::TestCase
  # Minitest 6에는 Object#stub이 없으므로 instance에 singleton method를 덮어
  # 테스트 더블을 만든다.
  def make_verifier(mst: "123456", article_exists: true)
    v = BlogLegalVerifier.new
    v.define_singleton_method(:mst_for) { |_| mst }
    v.define_singleton_method(:article_exists?) { |_, _| article_exists }
    v
  end

  setup { Rails.cache.clear }
  teardown { Rails.cache.clear }

  # ── 회귀 가드: 기존 금액·표현 검증 ──

  test "정상 본문은 issue 없이 통과한다" do
    text = "공사 추정가격 2천만원 이하인 경우 1인 견적이 가능합니다."
    result = make_verifier.verify(text)
    assert result[:valid], "issues=#{result[:issues].inspect}"
  end

  test "잘못된 금액 표현은 wrong_amount로 검출된다" do
    text = "전문공사 1억 이하인 경우 수의계약이 가능합니다."
    result = make_verifier.verify(text)
    assert_not result[:valid]
    assert(result[:issues].any? { |i| i[:type] == "wrong_amount" })
  end

  # ── 인용 환각 검증 ──

  test "검증 대상 외 법령은 통과한다 (CITATION_LAW_RE 미포함)" do
    text = "민법 제750조에 따라 손해배상을 청구한다."
    result = BlogLegalVerifier.new.verify(text)
    citation_issues = result[:issues].select { |i| i[:type] == "wrong_citation" }
    assert_empty citation_issues
  end

  test "MST 조회 실패 시 통과한다 (false positive 방지)" do
    text = "지방계약법 시행령 제401조에 따라."
    v = BlogLegalVerifier.new
    v.define_singleton_method(:mst_for) { |_| nil }
    # article_exists?는 호출되면 안 됨 (mst가 없으면 short-circuit)
    v.define_singleton_method(:article_exists?) { |_, _| flunk "should not be called" }

    result = v.verify(text)
    assert_empty result[:issues].select { |i| i[:type] == "wrong_citation" }
  end

  test "존재하는 조문은 통과한다" do
    text = "지방계약법 시행령 제25조 제1항에 따른 수의계약."
    result = make_verifier(article_exists: true).verify(text)
    assert_empty result[:issues].select { |i| i[:type] == "wrong_citation" }
  end

  test "존재하지 않는 조문은 wrong_citation으로 기록된다" do
    text = "지방계약법 시행령 제401조에 따라 처벌된다."
    result = make_verifier(article_exists: false).verify(text)

    citation_issues = result[:issues].select { |i| i[:type] == "wrong_citation" }
    assert_equal 1, citation_issues.size

    issue = citation_issues.first
    assert_equal "지방계약법 시행령 제401조", issue[:found]
    assert_empty issue[:correct], "auto-replace 비활성 — correct가 비어있어야 함"
    assert_match(/제401조를 찾을 수 없음/, issue[:note])
  end

  test "API 오류 시 article_exists?는 보수적으로 true(통과) 반환" do
    # rescue 절 단위 검증 — fetch_article 호출이 raise해도 true 폴백
    fake_api = Class.new do
      def fetch_article(*) = raise "API 타임아웃"
    end.new

    v = BlogLegalVerifier.new
    v.define_singleton_method(:article_exists?) do |mst, n|
      Rails.cache.fetch("blog_verify/article_exists/#{mst}/#{n}", expires_in: 7.days) do
        xml = fake_api.fetch_article(mst, n)
        !!(xml && xml.at_css("조문번호, 조문제목, 조문내용"))
      end
    rescue
      true
    end
    assert_equal true, v.send(:article_exists?, "999999", 25)
  end

  test "MAX_CITATIONS_PER_VERIFY 한도 초과 시 일부만 검증한다" do
    text = <<~T
      지방계약법 시행령 제401조,
      지방계약법 시행령 제402조,
      지방계약법 시행령 제403조,
      지방계약법 시행령 제404조에 따른다.
    T
    result = make_verifier(article_exists: false).verify(text)
    citation_issues = result[:issues].select { |i| i[:type] == "wrong_citation" }
    assert_equal BlogLegalVerifier::MAX_CITATIONS_PER_VERIFY, citation_issues.size
  end

  test "동일 인용 중복은 한 번만 검증한다" do
    text = <<~T
      지방계약법 시행령 제401조에 따라 ...
      앞서 언급한 지방계약법 시행령 제401조 규정처럼 ...
      또한 지방계약법 시행령 제401조의 적용 요건은 ...
    T
    result = make_verifier(article_exists: false).verify(text)
    citation_issues = result[:issues].select { |i| i[:type] == "wrong_citation" }
    assert_equal 1, citation_issues.size
  end

  # ── canonical_law_name ──

  test "약칭 + 시행령 접미사를 정식명으로 결합한다" do
    name = BlogLegalVerifier.new.send(:canonical_law_name, "지방계약법 시행령")
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령", name
  end

  test "약칭 + 시행규칙 접미사도 결합한다" do
    name = BlogLegalVerifier.new.send(:canonical_law_name, "지방계약법 시행규칙")
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙", name
  end

  test "정식명도 그대로 통과한다" do
    name = BlogLegalVerifier.new.send(:canonical_law_name, "공무원 여비 규정")
    assert_equal "공무원 여비 규정", name
  end
end
