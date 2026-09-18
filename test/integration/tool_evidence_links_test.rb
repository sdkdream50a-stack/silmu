# frozen_string_literal: true

require "test_helper"

# PHASE C / TOP10 — 도구 결과에서 «그래서 무엇을 쓰고 무엇을 조심하나» 로 이어지는가.
#
# 운영 실측(2026-09-18): 도구 4/4 결과에 감사사례 0 · 서식 0 이었다.
# 사용자가 요구한 흐름의 마지막 두 칸(서식·감사사례)이 끊겨 있었다.
#
# 이 테스트가 지키는 것은 «링크가 있다» 가 아니라 **«그 링크가 가리키는 것이 실재한다»** 다.
# 매핑을 손으로 적었으므로 오타 하나가 조용한 404 가 된다.
class ToolEvidenceLinksTest < ActionDispatch::IntegrationTest
  # ⚠️ 감사사례 slug 의 **존재**는 여기서 검사하지 않는다.
  #    첫 판본은 `AuditCase.exists?` 로 봤다가 전부 실패했는데, 운영에는 있고
  #    **test DB 픽스처에 없을 뿐**이었다(허브 링크 때와 같은 «내 검사가 보는 우주» 함정).
  #    · 코드 불변식(매핑 모양·서식 id·도구 키·렌더) → 이 파일
  #    · 데이터 불변식(그 slug 의 감사사례가 실재하는가) → 운영 스모크
  #      (tools/smoke_lecture_p0_0918.sh 의 TOP10 절이 매핑 링크를 전수 GET 한다)
  test "매핑 모양이 유효하다" do
    map = ToolEvidenceHelper::TOOL_EVIDENCE
    assert map.any?, "매핑이 비었다"

    map.each do |key, entry|
      assert entry.key?(:audit_case), "#{key} 에 audit_case 키가 없다"
      if (ac = entry[:audit_case])
        assert_equal 2, ac.size, "#{key} audit_case 는 [slug, 제목] 두 칸이다"
        assert ac[0].present? && ac[1].present?, "#{key} audit_case 에 빈 값이 있다"
        assert_match(/\A[a-z0-9-]+\z/, ac[0], "#{key} slug 모양이 아니다: #{ac[0]}")
      end
      if (t = entry[:template])
        assert t[0].is_a?(Integer), "#{key} 서식 id 가 정수가 아니다"
      end
    end
  end

  test "매핑이 가리키는 서식이 실제로 있다" do
    ids = ToolEvidenceHelper::TOOL_EVIDENCE.values.filter_map { |e| e[:template]&.first }.uniq
    valid = TemplatesController::TEMPLATES.map { |t| t[:id] }

    ids.each do |id|
      assert_includes valid, id, "서식 #{id} 가 없다"
    end
  end

  test "매핑의 도구 키가 실재하는 도구다" do
    ToolEvidenceHelper::TOOL_EVIDENCE.each_key do |key|
      get "/tools/#{key}"
      assert_response :success, "도구 /tools/#{key} 가 없다 — 매핑 키 오타"
    end
  end

  test "매핑된 도구 화면에 감사사례·서식 링크가 렌더된다" do
    {
      "contract-method"         => { audit: true,  template: true },
      "travel-calculator"       => { audit: true,  template: true },
      "overtime-calculator"     => { audit: true,  template: false },
      "budget-transfer-checker" => { audit: true,  template: false }
    }.each do |key, expect|
      get "/tools/#{key}"
      assert_response :success
      body = response.body

      audit_links = body.scan(%r{href="/audit-cases/[^"]+"}).size
      tpl_links   = body.scan(%r{href="/templates/\d+"}).size

      if expect[:audit]
        assert_operator audit_links, :>, 0, "#{key} 결과에 감사사례 링크가 없다"
      end
      if expect[:template]
        assert_operator tpl_links, :>, 0, "#{key} 에 서식 링크가 없다"
      else
        assert_equal 0, tpl_links, "#{key} 는 서식 매핑이 없는데 링크가 붙었다"
      end
    end
  end

  test "매핑이 없는 도구에는 아무것도 붙지 않는다" do  # 음성 대조
    # 빈칸이 거짓보다 낫다 — 자동 유사도로 아무거나 붙이지 않는다.
    assert_nil ToolEvidenceHelper::TOOL_EVIDENCE["salary-calculator"],
               "테스트 전제가 바뀌었다(이 도구에 매핑이 생겼다)"
    get "/tools/salary-calculator"
    assert_response :success
    assert_equal 0, response.body.scan(%r{href="/audit-cases/[^"]+"}).size,
                 "매핑이 없는 도구에 감사사례 링크가 붙었다"
  end

  test "카드 색은 빌드된 CSS 에 실제로 있는 값만 쓴다" do
    # Tailwind 는 동적 클래스명을 purge 한다. 2026-09-18 실측: hover:border-rose-400 이
    # CSS 에 없어 rose 카드만 hover 테두리가 죽었다. 그래서 색을 amber 로 바꿨다.
    css_path = Rails.root.join("app/assets/builds/application.css")
    skip "빌드된 CSS 없음(로컬 자산 미빌드)" unless css_path.exist?
    css = css_path.read

    colors = ToolEvidenceHelper.instance_method(:tool_evidence_slots)
    assert colors, "헬퍼가 사라졌다"

    %w[contract-method travel-calculator].each do |key|
      get "/tools/#{key}"
      response.body.scan(/border-(\w+)-400/).flatten.uniq.each do |c|
        assert css.include?(".border-#{c}-400"),
               "border-#{c}-400 이 빌드된 CSS 에 없다 — 화면에서 조용히 죽는다"
      end
    end
  end
end
