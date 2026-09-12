require "test_helper"

# EXP-SILMU-NONADS-01 배치·고지 회귀.
#
# ⚠️ 이 파일의 음성 판정("고지 없이는 안 나온다")은 양성대조가 통과할 때만 의미가 있다.
#    ENV 가 비면 파티셜은 **아무것도 렌더하지 않으므로**, 양성대조 없이 음성만 두면
#    전부 공허한 green 이 된다 — AdSense 테스트가 production 스텁 없이 공허했던 것과 같은 함정.
class ExamBookCtaTest < ActionDispatch::IntegrationTest
  DISCLOSURE = "쿠팡 파트너스 활동의 일환으로"

  def with_env(vars)
    old = vars.keys.index_with { |k| ENV[k] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| ENV[k] = v }
  end

  # ── 양성대조 ──
  test "POSITIVE CONTROL: CTA renders when enabled and free url present" do
    host! "exam.silmu.kr"
    with_env("EXAM_BOOK_CTA_ENABLED" => "1",
             "EXAM_BOOK_FREE_URL" => "https://example.test/free") do
      get "/quiz"
    end
    assert_response :success
    assert_includes response.body, 'data-surface-id="exam_book_cta"',
                    "CTA 가 안 나온다 — 이 파일의 음성 판정이 전부 공허해진다"
    assert_includes response.body, 'data-cta-id="examfree01"'
  end

  # ── 음성 판정 ──
  test "affiliate link never renders without the coupang disclosure" do
    host! "exam.silmu.kr"
    with_env("EXAM_BOOK_CTA_ENABLED" => "1",
             "EXAM_BOOK_FREE_URL" => "https://example.test/free",
             "EXAM_BOOK_AFFILIATE_URL" => "https://link.coupang.com/a/TEST") do
      get "/quiz"
    end
    assert_includes response.body, "link.coupang.com"
    assert_includes response.body, DISCLOSURE,
                    "제휴 링크가 고지 문구 없이 렌더됐다 — 쿠팡파트너스 정책 위반"
  end

  test "fail closed: nothing renders when free url is absent" do
    host! "exam.silmu.kr"
    with_env("EXAM_BOOK_CTA_ENABLED" => "1",
             "EXAM_BOOK_FREE_URL" => nil,
             "EXAM_BOOK_AFFILIATE_URL" => "https://link.coupang.com/a/TEST") do
      get "/quiz"
    end
    refute_includes response.body, 'data-surface-id="exam_book_cta"',
                    "무료 교재 URL 없이 제휴 링크만 나갔다 — 설계상 금지"
    refute_includes response.body, "link.coupang.com"
  end

  test "rollback: disabled flag removes the surface entirely" do
    host! "exam.silmu.kr"
    with_env("EXAM_BOOK_CTA_ENABLED" => "0",
             "EXAM_BOOK_FREE_URL" => "https://example.test/free") do
      get "/quiz"
    end
    refute_includes response.body, 'data-surface-id="exam_book_cta"'
  end

  # AdSense 축을 건드리지 않았다는 단언 — exam 은 미커버로 남아야 한다.
  test "exam pages remain AdSense-uncovered" do
    host! "exam.silmu.kr"
    with_env("EXAM_BOOK_CTA_ENABLED" => "1",
             "EXAM_BOOK_FREE_URL" => "https://example.test/free") do
      get "/quiz"
    end
    refute_includes response.body, "adsbygoogle",
                    "exam 에 광고가 생겼다 — 이 실험은 NON_ADSENSE 축이다"
  end
end
