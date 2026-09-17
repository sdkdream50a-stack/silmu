# frozen_string_literal: true

require "test_helper"

# P0-4 (LECTURE_READINESS_AUDIT) — 교육행정 홈 큐레이션.
#
# 막는 것 두 가지:
#   ① 같은 토픽이 «이달의 필수» 에 두 번 렌더되는 것 (edu 2·3·9월에 실제로 있었다)
#   ② 학교 사용자에게 sector=common · 원문 출처 없는 재구성 겸직 사례가 고정 노출되는 것
#      (운영 실측 2026-09-18: silmu-2026-concurrent-* 3건이 고정 노출 · edu 사례는 88건 있었다)
class HomeEduCurationTest < ActionDispatch::IntegrationTest
  # ── ① 큐레이션 중복
  test "SEASONAL_TOPICS 모든 sector·모든 월에 중복 slug 가 없다" do
    HomeController::SEASONAL_TOPICS.each do |sector, months|
      months.each do |month, slugs|
        dupes = slugs.tally.select { |_, n| n > 1 }.keys
        assert_empty dupes,
                     "#{sector} #{month}월에 중복 slug: #{dupes.inspect} — 카드가 두 번 렌더된다"
      end
    end
  end

  test "edu 큐레이션에 학교회계 전용 토픽이 들어 있다" do
    edu_slugs = HomeController::SEASONAL_TOPICS[:edu].values.flatten.uniq
    assert_includes edu_slugs, "school-budget-compilation",
                    "학교 탭 큐레이션에 학교회계 전용 토픽이 없다"
  end

  test "큐레이션 규칙이 바뀌면 캐시 버전이 올라가 있다" do
    # 순위·목록을 바꾸고 CURATION_VERSION 을 그대로 두면 운영에서 최대 1시간 옛 화면이 나간다.
    assert_operator HomeController::CURATION_VERSION, :>=, 4,
                    "CURATION_VERSION 을 올리지 않았다 — 캐시가 옛 큐레이션을 계속 서빙한다"
  end

  # ── ② 감사사례 선택
  test "교육행정 탭 감사사례는 edu sector 와 원문 출처 확인분을 먼저 고른다" do
    # 운영에서 문제가 됐던 형태를 그대로 만든다:
    #   common·재구성·최신  vs  edu·출처확인·과거
    common_recent = AuditCase.create!(
      slug: "test-common-reconstructed-newest", title: "공통 재구성 최신", sector: :common,
      severity: "중대", category: "복무", issue: "공통 재구성 사례 지적사항", published: true,
      is_reconstructed: true, verification_status: "RECONSTRUCTED",
      created_at: 1.day.ago
    )
    edu_verified = AuditCase.create!(
      slug: "test-edu-verified-older", title: "학교 출처확인 과거", sector: :edu,
      severity: "중대", category: "계약", issue: "학교 출처확인 사례 지적사항", published: true,
      is_reconstructed: false, verification_status: "OFFICIAL_SOURCE_VERIFIED",
      source_url: "https://www.sen.go.kr/example", source_year: 2025,
      created_at: 2.years.ago
    )

    get root_url(sector: "edu")
    assert_response :success

    picked = @controller.view_assigns["recent_audit_cases"]
    assert_not_nil picked, "감사사례가 뽑히지 않았다"

    assert_includes picked.map(&:slug), edu_verified.slug,
                    "edu·출처확인 사례가 학교 탭에서 밀렸다"
    if picked.map(&:slug).include?(common_recent.slug)
      assert_operator picked.index { |a| a.slug == edu_verified.slug }, :<,
                      picked.index { |a| a.slug == common_recent.slug },
                      "common·재구성 최신 사례가 edu·출처확인 사례보다 먼저 나온다"
    end
  end

  # 음성 대조 — common 탭의 동작은 바꾸지 않았다(최신순 유지).
  test "공통 탭은 종전처럼 최신순이다" do
    get root_url(sector: "common")
    assert_response :success
    picked = @controller.view_assigns["recent_audit_cases"]
    assert_not_empty picked

    # fixture 가 무엇이든 «created_at 내림차순» 이라는 성질 자체를 단정한다.
    assert_equal picked.map(&:created_at).sort.reverse, picked.map(&:created_at),
                 "공통 탭 정렬이 최신순이 아니다 — 이번 변경 범위가 아니다"

    # 그리고 공통 탭에서는 재구성 여부로 순서를 바꾸지 않는다(edu 탭에서만 바꿨다).
    expected = AuditCase.published.where(severity: %w[중대 보통])
                        .order(created_at: :desc).limit(3).map(&:slug)
    assert_equal expected, picked.map(&:slug), "공통 탭 선택 규칙이 바뀌었다"
  end

  # ── P1-3 함께 정정한 허위 AI 표기
  test "계약방식 카드가 «인공지능이 추천» 이라고 말하지 않는다" do
    get root_url
    assert_response :success
    assert_no_match(/인공지능이 추천/, response.body,
                    "규칙 기반 판정을 AI 추천이라고 말한다(ContractMethodService 는 AI 를 호출하지 않는다)")
    assert_match(/지방계약법령 기준표와 대조/, response.body)
  end
end
