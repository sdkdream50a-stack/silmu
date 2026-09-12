require "test_helper"

# 2026-09-12 AdSense 재활성화 — 배치 정책 회귀.
#
# AdSense 광고 게재위치 정책은 "applications"(입력·버튼·결과를 가진 계산기) 인접 배치를
# 우발 클릭 위험으로 금지한다. 옛 코드는 /tools 에 position 'tool-result' 로 광고를 넣었고
# 호출부 17곳이 아직 살아 있다 — 파티셜이 그것을 렌더하지 않는지 고정한다.
#
# ⚠️ 광고 렌더는 Rails.env.production? 뒤에 있다. 그 가드를 풀지 않으면 이 테스트는
#    "광고가 없다"를 항상 통과시키는 **공허한 green** 이 된다(2026-09-12 뮤테이션에서 실증:
#    옛 위험 설계를 되살려도 통과했다). 그래서 production 으로 스텁해 실제 분기를 탄다.
class AdsensePlacementTest < ActionDispatch::IntegrationTest
  # minitest 6 은 minitest/mock 을 기본 번들에서 뺐다. 의존성을 늘리지 않고 env 를 직접 교체한다.
  # ensure 로 반드시 되돌린다 — 누수되면 뒤따르는 테스트가 production 으로 돈다.
  def as_production
    original = Rails.env
    Rails.env = "production"
    yield
  ensure
    Rails.env = original.to_s
  end

  # ── 양성대조 — 이게 실패하면 아래 음성 판정은 전부 무의미하다 ──
  # 경로는 픽스처에서 가져온다(하드코딩한 slug 는 404 가 나고, 404 는 "광고 없음"을 공허하게 통과시킨다).
  # ⚠️ topics.yml 에 픽스처를 새로 추가하지 말 것 — home_controller_test 의 skip 임계(7)를 건드린다.
  test "POSITIVE CONTROL: content pages do render an ad unit in production" do
    host! "silmu.kr"

    as_production { get "/guides/#{guides(:one).slug}" }

    assert_response :success
    assert_includes response.body, "adsbygoogle",
                    "콘텐츠 페이지에 광고가 안 나온다 — 이 테스트 파일의 음성 판정이 전부 공허해진다"
    assert_includes response.body, "pagead2.googlesyndication.com",
                    "콘텐츠 페이지에 AdSense 로더가 없다"
  end

  # ── 음성 판정 — 위 양성대조가 통과할 때만 의미가 있다 ──
  test "tool pages never render an ad unit" do
    host! "silmu.kr"

    as_production { get "/tools/budget-execution-rate" }

    assert_response :success
    refute_includes response.body, "adsbygoogle",
                    "계산기 페이지에 광고가 렌더됐다 — AdSense 게재위치 정책(application 인접) 위반 위험"
  end

  test "tool pages do not load the adsense script" do
    host! "silmu.kr"

    as_production { get "/tools/insurance-calculator" }

    assert_response :success
    refute_includes response.body, "pagead2.googlesyndication.com",
                    "계산기 페이지에 AdSense 로더가 들어갔다 — layout 조건에서 tools 를 빼야 한다"
  end

  # 옛 라벨 "AI 응답 API 비용 충당을 위해 광고가 표시됩니다" 는 정책 라벨 요건을 만족하지 않고
  # 클릭 유도 계열이다. 어떤 페이지에서도 되살아나면 안 된다.
  test "cost-justification ad label never reappears" do
    host! "silmu.kr"

    [ "/tools/budget-execution-rate", "/guides/#{guides(:one).slug}", "/" ].each do |path|
      as_production { get path }
      refute_includes response.body, "비용 충당", "#{path} 에 옛 광고 라벨 문구가 되살아났다"
    end
  end

  test "ad label is the neutral one the policy requires" do
    host! "silmu.kr"

    as_production { get "/guides/#{guides(:one).slug}" }

    assert_includes response.body, ">광고<", "중립 라벨 '광고' 가 없다"
  end
end
