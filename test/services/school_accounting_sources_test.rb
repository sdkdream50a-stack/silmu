# frozen_string_literal: true

require "test_helper"

# P4 §8·§9 — 학교회계 source 정규화.
# 핵심 불변식: **다수결을 전국 규칙으로 올리지 않는다** · 값이 없으면 지어내지 않고 UNTRACKED 다.
class SchoolAccountingSourcesTest < ActiveSupport::TestCase
  S = SchoolAccountingSources

  setup { S.reset! }

  test "3개 층이 모두 있고 층마다 «기한 권위» 가 다르다" do
    summary = S.layer_summary
    assert_equal %w[ANNUAL_GUIDELINE NATIONAL_CORE REGIONAL_RULE], summary.keys.sort
    assert_equal "DEADLINE", summary["NATIONAL_CORE"][:authority]
    assert_equal "DEADLINE_IF_UNIFORM", summary["REGIONAL_RULE"][:authority]
    assert_equal "REFERENCE_ONLY", summary["ANNUAL_GUIDELINE"][:authority]
  end

  test "교육규칙 17개 전수가 등록돼 있고 모두 REGIONAL_RULE 이다" do
    rules = S.regional_rules
    assert_equal 17, rules.size
    assert(rules.all? { |r| r.layer == "REGIONAL_RULE" })
    assert_equal 17, rules.map(&:region).uniq.size
  end

  test "«기한으로 쓸 수 있는 권위» 는 법률 층에만 있다 — 다수결 승격 금지" do
    assert(S.national_core.all?(&:deadline_authority?))
    refute(S.regional_rules.any?(&:deadline_authority?))
    refute(S.annual_guidelines.any?(&:deadline_authority?))
  end

  test "§8 metadata 가 전부 채워진다 — 공개 원문 URL 은 일련번호에서 파생한다" do
    seoul = S.regional_rules.find { |r| r.region == "서울" }
    assert_equal "STRUCTURED_API", seoul.source_type
    assert_equal "EDU_OFFICE", seoul.jurisdiction
    assert_equal "1263963", seoul.official_identifier
    assert_equal "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=1263963", seoul.source_url
    assert_equal Date.new(2016, 11, 14), seoul.effective_date
    assert_equal "ACTIVE", seoul.status
  end

  test "추적 중인 문서가 없으면 시점 정보를 지어내지 않고 UNTRACKED 로 말한다" do
    rec = S.regional_rules.first
    refute rec.tracked?
    assert_equal S::UNTRACKED, rec.fetched_at
    assert_equal S::UNTRACKED, rec.version_hash
    assert_equal S::UNTRACKED, rec.verified_at
    assert_equal S::UNTRACKED, rec.supersedes
  end

  test "freshness engine 에 등록되면 같은 레코드가 시점 정보를 갖는다" do
    src = AuthoritySource.create!(key: "t_ordin", name: "t", source_type: "STRUCTURED_API",
                                  fetch_strategy: "ordin_api", authority_tier: 1)
    rec = S.regional_rules.find { |r| r.region == "서울" }
    doc = AuthorityDocument.create!(key: rec.key, authority_source: src, title: rec.title,
                                    document_type: "LOCAL_RULE", official_identifier: rec.official_identifier)
    v = AuthorityVersion.create!(authority_document: doc, content_hash: "abc123", fetched_at: Time.current,
                                 version_identifier: "1263963")
    doc.update!(current_version: v)
    S.reset!
    got = S.regional_rules.find { |r| r.region == "서울" }
    assert got.tracked?
    assert_equal "abc123", got.version_hash
    refute_equal S::UNTRACKED, got.fetched_at
  end

  test "등록부 key 규약은 seed 와 이 서비스가 같은 함수 하나를 쓴다" do
    assert_equal "school_accounting_rule_서울", S.ordin_key("서울")
    assert_equal S.ordin_key("전남"), S.regional_rules.find { |r| r.region == "전남" }.key
  end

  test "달력 엔진이 쓰는 rules 키는 그대로다 — P3 비회귀" do
    SchoolAccountingCalendar.instance_variable_set(:@regional_rules, nil)
    assert_equal 17, SchoolAccountingCalendar.regional_rules.size
    assert SchoolAccountingCalendar.regional_rules.all? { |r| r[:closing_type].present? }
  end
end
