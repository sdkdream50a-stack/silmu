# frozen_string_literal: true

require "test_helper"

# P4 §10 — 관할 전수 census.
# 이 테스트의 목적은 «전부 판정됐다» 가 아니라 **«전부 census 에 있다»** 를 강제하는 것이다.
# UNKNOWN 은 허용하되 침묵은 허용하지 않는다.
class ToolTrustScopeTest < ActiveSupport::TestCase
  include ToolsHelper
  include Rails.application.routes.url_helpers

  setup { ToolTrust.reset! }

  # 도구 목록을 하드코딩하지 않는다 — 레지스트리에서 **파생**한다.
  # 새 도구를 추가하면 census 를 채우기 전까지 이 테스트가 막는다.
  def active_tool_keys
    tools_registry.reject { |t| t[:unlisted] }.map do |t|
      p = t[:path].to_s
      p.start_with?("/tools/") ? p.sub("/tools/", "") : p
    end
  end

  test "활성 도구 전부가 census 에 있다 — 빠진 도구 0" do
    missing = active_tool_keys - ToolTrust.jurisdiction_scope.keys
    assert_empty missing, "census 미등록 도구: #{missing.join(', ')}"
  end

  test "census 에 활성 도구가 아닌 유령 항목이 없다" do
    ghosts = ToolTrust.jurisdiction_scope.keys - active_tool_keys
    assert_empty ghosts, "활성 도구가 아닌 census 항목: #{ghosts.join(', ')}"
  end

  # ⚠️ `scope_census` 는 `scope_for` 의 정화기를 거치므로 YAML 오탈자가 UNKNOWN 으로 바뀌어
  #    **보이지 않는다**(독립 리뷰 R1 — 항진식). 등록부 **원본값**을 직접 본다.
  test "등록부 원본 scope 가 닫힌 어휘만 쓴다 — 오탈자가 UNKNOWN 으로 숨지 않는다" do
    bad = ToolTrust.jurisdiction_scope.reject { |_k, v| ToolTrust::SCOPES.include?(v["scope"].to_s) }
    assert_empty bad.keys, "닫힌 어휘 밖의 원본값: #{bad.inspect}"
  end

  test "원본값 검사가 실제로 오탈자를 잡는다" do  # 음성 대조 — 같은 탐지 루프를 돌린다
    injected = ToolTrust.jurisdiction_scope.merge("위조도구" => { "scope" => "SCHOOL_DIRCT" })
    bad = injected.reject { |_k, v| ToolTrust::SCOPES.include?(v["scope"].to_s) }
    assert_equal [ "위조도구" ], bad.keys
  end

  test "UNKNOWN 에는 «무엇이 없어서 모르는가» 가 반드시 있다" do
    blank = ToolTrust.scope_census.values.select { |s| !s.known? && s.reason.to_s.strip.empty? }
    assert_empty blank.map(&:tool_key), "reason 없는 UNKNOWN: #{blank.map(&:tool_key).join(', ')}"
  end

  # 현재 census 는 전부 정상값이라 정화기가 **한 번도 실행되지 않는다**.
  # 위반값을 주입해 정화 루프를 실제로 돌린다(양성 대조).
  test "닫힌 어휘를 벗어난 값은 조용히 통과하지 않고 UNKNOWN 으로 정화된다" do
    original = ToolTrust.method(:jurisdiction_scope)
    ToolTrust.define_singleton_method(:jurisdiction_scope) do
      { "위조도구" => { "scope" => "SCHOOL_DIRECT_ALL_GOOD", "reason" => nil } }
    end
    s = ToolTrust.scope_for("위조도구")
    assert_equal "UNKNOWN", s.scope
    refute s.school_usable?
  ensure
    ToolTrust.define_singleton_method(:jurisdiction_scope, original)
  end

  test "등록되지 않은 키는 조용히 안전값이 아니라 UNKNOWN 으로 떨어진다" do
    s = ToolTrust.scope_for("이런-도구는-없다")
    refute s.known?
    assert_includes s.reason, "등록되지 않은"
  end

  # 기존 화면 판정(jurisdiction.school_differs)과 census 가 어긋나면 둘 중 하나가 거짓말이다.
  test "school_differs 가 있는 도구는 SCHOOL_DIRECT 가 아니다" do
    with_note = ToolTrust.registered_tool_keys.select { |k| ToolTrust.for(k).jurisdiction&.school_note? }
    assert_operator with_note.size, :>=, 6
    with_note.each do |k|
      refute_equal "SCHOOL_DIRECT", ToolTrust.scope_for(k).scope,
                   "#{k}: 학교 적용 차이가 등록돼 있는데 census 는 SCHOOL_DIRECT 라고 한다"
    end
  end

  # P0 가 학교 허브에서 뺀 자산은 census 에서도 LOCAL_GOV_ONLY 여야 한다(두 판정이 같은 사실을 말한다).
  test "P0 가 학교 허브 핵심에서 제외한 도구는 LOCAL_GOV_ONLY 다" do
    %w[budget-category-finder budget-transfer-checker].each do |k|
      assert_equal "LOCAL_GOV_ONLY", ToolTrust.scope_for(k).scope
    end
  end

  test "school_usable? 는 LOCAL_GOV_ONLY 와 UNKNOWN 을 학교 사용 가능으로 보지 않는다" do
    refute ToolTrust.scope_for("contingency-fund").school_usable?
    refute ToolTrust.scope_for("salary-calculator").school_usable?
    assert ToolTrust.scope_for("contract-method").school_usable?
  end

  test "도구 수 39 비회귀 — census 크기가 활성 도구 수와 같다" do
    assert_equal 39, active_tool_keys.size
    assert_equal 39, ToolTrust.jurisdiction_scope.size
  end
end
