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

  # ── §25①1호(긴급) ↔ §25①5호(소액수의 금액기준) 구분 (2026-09-06) ──
  #
  # 검증기는 «정답» 을 가르치는 자리다. 여기에 조문이 틀리면 본문 오류를 옳다고 고쳐 준다.
  # 금액 기준의 근거는 §25①5호(가목 공사 · 나목 물품·용역)이지 §25①1호(천재지변·긴급)가 아니다.

  test "양성 대조: 잘못된 물품·용역 한도는 §25①5호 나목을 정답으로 알려 준다" do
    result = make_verifier.verify("물품·용역 5천만원 이하이면 수의계약이 가능합니다.")
    issue = result[:issues].find { |i| i[:type] == "wrong_amount" }
    assert issue, "물품·용역 한도 오류를 잡지 못한다"
    assert_equal "물품·용역 추정가격 2천만원 이하", issue[:correct]
    assert_includes issue[:source], "제25조 제1항 제5호 나목"
    assert_not_includes issue[:source], "제25조 제1항 제1호"
  end

  test "양성 대조: 잘못된 공사 한도는 §25①5호 가목을 정답으로 알려 준다" do
    result = make_verifier.verify("종합공사 6억원 이하이면 수의계약이 가능합니다.")
    issue = result[:issues].find { |i| i[:type] == "wrong_amount" }
    assert issue, "종합공사 한도 오류를 잡지 못한다"
    assert_includes issue[:source], "제25조 제1항 제5호 가목"
  end

  test "음성 대조: 어떤 금액 룰도 §25①1호를 근거로 제시하지 않는다" do
    BlogLegalVerifier::AMOUNT_CHECKS.each do |rule|
      assert_not_includes rule[:source], "제25조 제1항 제1호",
                          "금액 기준을 긴급 조항에 매달았다: #{rule[:correct]}"
    end
  end

  test "음성 대조: §30 견적 룰은 §25 로 옮겨지지 않았다" do
    s30 = BlogLegalVerifier::AMOUNT_CHECKS.select { |r| r[:source].include?("제30조") }
    assert_equal 2, s30.size, "§30 룰 2건이 유지되지 않았다"
    assert(s30.none? { |r| r[:source].include?("제25조") }, "§30 룰에 §25 가 섞였다")
  end

  test "컨텍스트 게이트는 조문 번호를 따라 옮겨졌다 — 보증금 면제 문맥은 여전히 통과" do
    # 게이트는 «source 가 §25 금액 룰인가» 로 걸린다. 제1호→제5호 로 바꾸면서
    # 게이트 문자열을 함께 옮기지 않으면 이 문맥이 오검출로 돌아온다.
    text = "계약보증금은 시행령 제51조에 따라 물품·용역 5천만원 이하이면 면제할 수 있습니다."
    result = make_verifier.verify(text)
    assert_empty result[:issues].select { |i| i[:type] == "wrong_amount" },
                 "보증금 면제 문맥을 수의계약 한도 오류로 오검출한다"
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
