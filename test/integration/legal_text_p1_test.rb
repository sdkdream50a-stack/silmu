# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P1 — 도구 안내 문구의 법령 오기 (law.go.kr 원문 대조).
# · 지방보조금 실적보고 = 사유 발생일부터 2개월 (지방보조금법 제17조제1항 · 시행령 제9조제1항). «3개월» 은 제9조제4항 삭감 구간.
# · 입찰공고 = 금액과 관계없이 지정정보처리장치 (지방계약법 시행령 제33조제1항).
# · 설계변경 증액 = 86% 미만 낙찰 공사가 누계 10% 이상 증액 시 단체장 승인 (시행령 제74조제3항) — «10% 이내만 가능» 이 아니다.
class LegalTextP1Test < ActionDispatch::IntegrationTest
  test "지방보조금 실적보고 기한을 3개월로 안내하지 않는다" do
    %w[/tools/audit-readiness-checker /tools/subsidy-settlement-checker].each do |path|
      get path
      assert_response :success
      assert_includes response.body, "시행령 제9조제1항", path
      assert_not_includes response.body, "보조사업자 3개월", path
      assert_not_includes response.body, "보조사업자는 3개월", path
    end
  end

  test "입찰공고 전자공개를 1억원 이상으로 한정하지 않는다" do
    get "/tools/contract-legality-check"
    assert_response :success
    assert_includes response.body, "금액과 관계없이 지정정보처리장치"
    assert_not_includes response.body, "공고 등록 여부 확인 (추정가격 1억원 이상)"
  end

  test "설계변경 물량 증감 주의사항이 시행령 제74조제3항을 따른다" do
    cautions = DesignChangeReviewService::CHANGE_REASONS.values.flat_map { |t| t[:cautions] }
    assert cautions.any? { |c| c.include?("86% 미만") && c.include?("제74조제3항") }
    assert cautions.none? { |c| c.include?("총공사비의 10% 이내에서 가능") }
  end
end
