# frozen_string_literal: true

require "test_helper"

# P1-3 §17 — positive / negative / ambiguous fixture 를 모두 갖는다.
# P0 에서 "0건" 단정 3개 중 2개가 양성대조 후 뒤집혔다. 검출기는 "있는 것을 세는지" 먼저 증명한다.
class InternalMetadataFilterTest < ActiveSupport::TestCase
  # ── POSITIVE: 실제 운영에서 공개 노출됐던 문자열. 반드시 차단되어야 한다 ──
  POSITIVE = {
    "커밋 범위" => "Phase A~E batch 01~03 (commits eed3ceb..12dff5d) — 법제처 OPEN API 5단계 게이트 검증",
    "lawId 목록" => "법제처 OPEN API mcp spot check + 부정확 정정 (lawId 001234·002345, 2026-05-19 batch 02)",
    "내부 대시보드 키" => "sen_2025_audit_disclosure_dashboard",
    "backlog 메모" => "GOE 2021 경기교육청 감사보고서 (조문번호 명시 없음 — 차후 정밀화 backlog)",
    "운영 정합 꼬리표" => "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: 지방계약법 시행령 제25조. 운영 정합",
    "parser 버전" => "parser_version 3.2 backfill 완료",
    "import job" => "import_job=seed_2026 internal"
  }.freeze

  # ── NEGATIVE: 사용자에게 보여도 되는 정상 출처. 반드시 통과해야 한다 ──
  NEGATIVE = {
    "기관 발행물" => "경기도교육청 감사관실 · 감사사례집 · 2021",
    "법제처" => "법제처 국가법령정보센터",
    "서울교육청" => "서울특별시교육청 감사관 2025 감사결과",
    "법령명" => "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령 제25조"
  }.freeze

  test "POSITIVE — 내부 엔지니어링 메타데이터를 전부 차단한다" do
    POSITIVE.each do |name, text|
      assert InternalMetadataFilter.internal?(text), "차단 실패(#{name}): #{text}"
      assert_nil InternalMetadataFilter.public_only(text), "공개 통과됨(#{name}): #{text}"
    end
  end

  test "NEGATIVE — 정상 출처는 통과시킨다 (검출기가 과잉 차단하지 않음)" do
    NEGATIVE.each do |name, text|
      refute InternalMetadataFilter.internal?(text), "과잉 차단(#{name}): #{text}"
      assert_equal text, InternalMetadataFilter.public_only(text), "통과 실패(#{name})"
    end
  end

  test "AMBIGUOUS — 빈 값은 차단도 통과도 아닌 nil 로 처리한다" do
    [ nil, "", "   " ].each do |blank|
      refute InternalMetadataFilter.internal?(blank)
      assert_nil InternalMetadataFilter.public_only(blank)
    end
  end

  test "matched_patterns 는 어떤 규칙에 걸렸는지 알려준다" do
    assert_not_empty InternalMetadataFilter.matched_patterns(POSITIVE["커밋 범위"])
    assert_empty InternalMetadataFilter.matched_patterns(NEGATIVE["법제처"])
  end
end
