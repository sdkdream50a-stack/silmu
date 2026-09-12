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

  # ── PHASE_B (2026-09-13) — 제휴 CTA 를 실제로 켜는 배포의 회귀 ────────────────
  #
  # 위 5개는 PHASE_A(무료 CTA only)를 지켰다. 아래는 «제휴 링크가 켜진 상태» 의 계약이다.
  # 왜 따로 필요한가: PHASE_A 테스트는 affiliate 축에 대해 «없을 때 없다» 만 쟀고,
  # 그건 「없으면 참」인 술어라 제휴 CTA 자체의 계약을 하나도 재지 않는다.

  TARGET_PAGES = %w[/quiz /subjects /exam-info].freeze
  FREE_ENV = { "EXAM_BOOK_CTA_ENABLED" => "1", "EXAM_BOOK_FREE_URL" => "https://example.test/free" }.freeze
  AFF_URL = "https://link.coupang.com/a/TESTLINK"

  # A — 제휴 URL 이 없으면 제휴 CTA 와 고지 문구가 **둘 다** 없다. 무료 CTA 는 그대로 있다.
  #     (기존 "fail closed" 테스트는 **무료** URL 부재를 쟀다. 이건 **제휴** URL 부재다 — 다른 축.)
  test "A: without affiliate url the affiliate CTA and disclosure are both absent, free CTA survives" do
    host! "exam.silmu.kr"
    with_env(FREE_ENV.merge("EXAM_BOOK_AFFILIATE_URL" => nil)) { get "/quiz" }
    assert_includes response.body, 'data-cta-id="examfree01"', "무료 CTA 가 사라졌다"
    refute_includes response.body, 'data-cta-id="exambook01"'
    refute_includes response.body, DISCLOSURE,
                    "제휴 링크 없이 고지 문구만 남았다 — 고지는 제휴 링크와 한 몸이다"
  end

  # C — 무료가 항상 **먼저**다. 순서는 이 실험의 신뢰 축이므로 존재가 아니라 위치를 잰다.
  #     (둘 다 «존재한다» 만 재면 유료를 위로 올려도 green 이다.)
  test "C: the free CTA always precedes the affiliate CTA in document order" do
    host! "exam.silmu.kr"
    with_env(FREE_ENV.merge("EXAM_BOOK_AFFILIATE_URL" => AFF_URL)) { get "/quiz" }
    free_at = response.body.index('data-cta-id="examfree01"')
    aff_at  = response.body.index('data-cta-id="exambook01"')
    assert free_at, "무료 CTA 가 없다"
    assert aff_at, "제휴 CTA 가 없다"
    assert free_at < aff_at,
           "유료 교재가 무료 공식 교재보다 위에 왔다 — 조달청 표준교재가 유일한 공식 교재다"
  end

  # E — cta_id 는 계약값 2개뿐이다. 오타·임의 변경은 GA4 에서 영구 미귀속이 된다(사후 수정 불가).
  test "E: only the two contracted cta_ids exist, and the affiliate anchor is exambook01" do
    host! "exam.silmu.kr"
    with_env(FREE_ENV.merge("EXAM_BOOK_AFFILIATE_URL" => AFF_URL)) { get "/quiz" }
    ids = response.body.scan(/data-cta-id="([^"]*)"/).flatten.uniq.sort
    assert_equal %w[exambook01 examfree01], ids, "계약 밖의 cta_id 가 렌더됐다: #{ids.inspect}"
    # 제휴 링크를 든 앵커가 바로 exambook01 이어야 한다 — 두 id 가 뒤바뀌면 위 단언은 통과한다.
    assert_match(/href="#{Regexp.escape(AFF_URL)}"[^>]*data-cta-id="exambook01"/, response.body,
                 "제휴 URL 을 든 앵커의 cta_id 가 exambook01 이 아니다 — 귀속이 뒤바뀐다")
    assert_match(/href="#{Regexp.escape(AFF_URL)}"[^>]*rel="[^"]*sponsored/, response.body,
                 "제휴 링크에 rel=sponsored 가 없다")
  end

  # F — 클릭 계측이 없으면 primary_metric(cta_click_rate) 자체를 못 잰다.
  test "F: GA4 cta_click instrumentation is present for the CTA surface" do
    host! "exam.silmu.kr"
    with_env(FREE_ENV.merge("EXAM_BOOK_AFFILIATE_URL" => AFF_URL)) { get "/quiz" }
    assert_includes response.body, '"cta_click"'
    assert_includes response.body, "data-cta-id"
    assert_includes response.body, 'surface_id: "exam_book_cta"'
  end

  # G — 세 target page 가 **같은** 계약을 렌더한다. 한 페이지만 보고 PASS 하면 분모가 어긋난다.
  test "G: all three target pages render the identical CTA contract" do
    TARGET_PAGES.each do |path|
      host! "exam.silmu.kr"
      with_env(FREE_ENV.merge("EXAM_BOOK_AFFILIATE_URL" => AFF_URL)) { get path }
      assert_response :success, "#{path} 가 200 이 아니다"
      assert_includes response.body, 'data-surface-id="exam_book_cta"', "#{path}: 표면 없음"
      assert_includes response.body, 'data-cta-id="examfree01"', "#{path}: 무료 CTA 없음"
      assert_includes response.body, 'data-cta-id="exambook01"', "#{path}: 제휴 CTA 없음"
      assert_includes response.body, DISCLOSURE, "#{path}: 고지 문구 없음"
    end
  end
end
