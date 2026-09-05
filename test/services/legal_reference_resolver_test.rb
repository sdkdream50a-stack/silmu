# frozen_string_literal: true

require "test_helper"

# P1-4 §15~§17 — 링크는 확실할 때만 만든다.
# KNOWN → 반드시 resolve / UNKNOWN → resolve 금지 / AMBIGUOUS → unresolved
class LegalReferenceResolverTest < ActiveSupport::TestCase
  test "KNOWN — 허용목록 법령은 공식 URL 로 해석된다" do
    refs = LegalReferenceResolver.resolve("지방계약법 시행령 제25조 제1항 제5호")
    assert_equal 1, refs.size
    ref = refs.first
    assert ref.resolved?, "허용목록 법령이 해석되지 않음"
    assert_equal "HIGH", ref.confidence
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령", ref.canonical_name
    assert_equal "https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률시행령", ref.official_url
    assert_equal "제25조 제1항 제5호", ref.article_text
  end

  test "KNOWN — 약칭도 정식명으로 해석된다" do
    ref = LegalReferenceResolver.resolve("국가계약법 제11조").first
    assert ref.resolved?
    assert_equal "국가를 당사자로 하는 계약에 관한 법률", ref.canonical_name
  end

  test "UNKNOWN — 허용목록에 없는 자치법규·내부지침은 링크하지 않는다" do
    [
      "경기도 공립학교회계 규칙 제12조",
      "학교회계 예산편성 기본지침(정책기획관)",
      "입찰 및 계약집행기준",
      "공무원 비위사건 처리규정"
    ].each do |text|
      refs = LegalReferenceResolver.resolve(text)
      assert refs.any?, "파싱 자체가 실패: #{text}"
      refs.each do |r|
        refute r.resolved?, "허용목록 밖인데 링크 생성됨: #{text} → #{r.official_url}"
        assert_equal "not_in_allowlist", r.resolution_source
      end
    end
  end

  test "AMBIGUOUS — 앞선 법령이 없는 대용어는 해석하지 않는다" do
    ref = LegalReferenceResolver.resolve("같은법 시행령 제5조").first
    refute ref.resolved?
    assert_equal "anaphora_unresolved", ref.resolution_source
  end

  test "대용어 — 앞선 법령이 하나뿐이면 상속해 해석한다" do
    refs = LegalReferenceResolver.resolve("지방계약법 제30조, 시행령 제90조, 시행규칙 제75조")
    assert_equal 3, refs.size
    assert refs.all?(&:resolved?), "하위법령 상속 해석 실패"
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령", refs[1].canonical_name
    assert_equal "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙", refs[2].canonical_name
  end

  test "괄호 안 쉼표로 분리하지 않는다" do
    refs = LegalReferenceResolver.resolve("세입세출외현금 관리요령(재무기획관-40945, 2020.12.31.)")
    assert_equal 1, refs.size, "괄호 안에서 잘림: #{refs.map(&:raw).inspect}"
    refute refs.first.resolved?
  end

  test "여러 법이 섞여도 각각 독립적으로 해석한다" do
    refs = LegalReferenceResolver.resolve("지방공무원법 제65조의3 / 국가공무원법 제73조의3, 경기도 규칙 제3조")
    assert_equal 3, refs.size
    assert refs[0].resolved?
    assert refs[1].resolved?
    refute refs[2].resolved?, "자치법규가 링크됨"
  end

  test "생성 URL 은 운영에서 이미 쓰는 규약을 따른다" do
    # SeoHelper#legislation_ref 와 동일한 형식이어야 한다 (새 URL 스킴을 발명하지 않는다)
    url = LegalReferenceResolver.official_url_for("지방공무원법")
    assert_equal "https://www.law.go.kr/법령/지방공무원법", url
  end
end
