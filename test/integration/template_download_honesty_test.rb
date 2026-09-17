# frozen_string_literal: true

require "test_helper"

# P0-3 (LECTURE_READINESS_AUDIT) — 서식 다운로드 «가짜 성공» 금지.
#
# 실측 2026-09-18: repo 에 .hwp/.hwpx/.xlsx/.docx/.pdf 파일이 0개이고, templates 는
#   ActiveStorage 첨부도 없고 라우트도 index/show 뿐이다. 그런데 26종 상세 페이지에
#   «HWP 다운로드»·«PDF 다운로드» 버튼이 핸들러(onclick/href/form) 없이 그려져 있었다.
#   연수 청중이 누르면 아무 일도 일어나지 않는다.
#
# 이 테스트가 강제하는 것: **파일이 없으면 버튼도 없다.**
#   파일을 확보해 다운로드를 붙일 때는 이 테스트를 «href 가 200 과 파일을 돌려준다» 로 바꿔라.
#   버튼만 되살리고 이 테스트를 지우는 것은 바로 이 결함으로 돌아가는 것이다.
class TemplateDownloadHonestyTest < ActionDispatch::IntegrationTest
  # 다운로드를 실제로 수행할 수 있는 표식 — 하나라도 있으면 «동작하는 버튼» 이다.
  ACTIONABLE = /onclick=|href=|data-(action|turbo-)|form action=/

  # 서식 파일이 놓일 수 있는 위치만 본다.
  #   ⚠️ 처음에 Rails.root 전체를 glob 했다가 **CI 에서만 실패**했다 — CI 는 gem 을
  #      repo 안 `vendor/bundle` 에 설치하므로 combine_pdf·prawn 의 fixture PDF 가 걸렸다.
  #      로컬은 gem 이 ~/.rbenv 에 있어 통과했다. 검사 범위를 서식이 실제로 서빙될 수 있는
  #      경로로 좁힌다 — 「내 probe 가 보는 우주를 먼저 확인한다」.
  ASSET_ROOTS = %w[public app/assets storage db/files lib/assets].freeze
  FORM_EXTENSIONS = %w[hwp hwpx xlsx docx pdf].freeze

  test "서식 파일이 repo 에 실제로 없다는 전제가 유지된다" do
    # 전제가 바뀌면(파일이 추가되면) 이 테스트가 먼저 알려서, 아래 단정을 다시 짜게 한다.
    found = ASSET_ROOTS.flat_map do |root|
      FORM_EXTENSIONS.flat_map { |ext| Dir.glob(Rails.root.join(root, "**", "*.#{ext}").to_s) }
    end
    found = found.reject { |f| f.include?("/node_modules/") || f.include?("/vendor/") }

    assert_empty found,
                 "서식 파일이 생겼다(#{found.first(3).inspect}) — 이제 «준비 중» 대신 실제 다운로드를 제공하고 이 테스트를 다시 짜라"
  end

  # 위 검사가 «아무 곳도 보지 않아» 통과하는 것을 막는다(양성 대조).
  test "전제 검사가 실제로 파일을 볼 수 있는 범위를 본다" do
    probe = Rails.root.join("public", "__form_probe__.pdf")
    File.write(probe, "%PDF-1.4 probe")
    begin
      found = ASSET_ROOTS.flat_map do |root|
        FORM_EXTENSIONS.flat_map { |ext| Dir.glob(Rails.root.join(root, "**", "*.#{ext}").to_s) }
      end
      assert_includes found, probe.to_s,
                      "심어 둔 파일을 못 찾는다 — 전제 검사가 빈 우주를 보고 있다"
    ensure
      FileUtils.rm_f(probe)
    end
  end

  test "26종 상세 전수 — 핸들러 없는 «다운로드» 버튼이 0개다" do
    assert_equal 26, TemplatesController::TEMPLATES.size, "서식 수가 바뀌었다 — 전수 범위를 다시 확인하라"

    TemplatesController::TEMPLATES.each do |t|
      get template_url(t[:id])
      assert_response :success, "서식 #{t[:id]}(#{t[:title]}) 상세가 200 이 아니다"

      # <button> ... 다운로드 ... </button> 조각을 모두 꺼내 «동작 표식» 이 있는지 본다.
      dead = response.body.scan(%r{<button[^>]*>.*?</button>}m)
                     .select { |b| b.include?("다운로드") }
                     .reject { |b| b.match?(ACTIONABLE) }

      assert_empty dead,
                   "서식 #{t[:id]}(#{t[:title]}): 눌러도 아무 일 없는 다운로드 버튼 #{dead.size}개"
    end
  end

  test "26종 상세 전수 — 제공하지 못한다는 사실을 화면에 쓴다" do
    TemplatesController::TEMPLATES.each do |t|
      get template_url(t[:id])
      assert_response :success
      assert_match(/다운로드는 준비 중입니다/, response.body,
                   "서식 #{t[:id]}: 파일을 못 준다는 사실이 화면에 없다")
      assert_match(/미리보기 화면<\/strong>을 그대로 인쇄/, response.body,
                   "서식 #{t[:id]}: 대안(인쇄)을 안내하지 않는다")
    end
  end

  test "인쇄 버튼은 실제로 동작한다" do
    get template_url(1)
    assert_response :success
    assert_match(/onclick="window\.print\(\)"/, response.body, "인쇄 버튼에 핸들러가 없다")
    assert_match(/미리보기 인쇄/, response.body)
  end

  test "동작하지 않던 «저장» 버튼이 없다" do
    get template_url(1)
    assert_response :success
    assert_no_match(/bookmark_border/, response.body,
                    "핸들러 없는 저장(북마크) 버튼이 남아 있다")
  end

  test "26종 전부에 하드코딩된 «최종 수정일» 이 없다" do
    TemplatesController::TEMPLATES.each do |t|
      get template_url(t[:id])
      assert_response :success
      assert_no_match(/2024\.01\.15/, response.body,
                      "서식 #{t[:id]}: 26종 공통 하드코딩 날짜가 남아 있다")
      assert_no_match(/최종 수정일/, response.body,
                      "서식 #{t[:id]}: 근거 없는 최종 수정일 항목이 남아 있다")
    end
  end

  test "목록의 «다운로드» 라벨이 미리보기와 같은 URL 로 가지 않는다" do
    get templates_url
    assert_response :success
    assert_no_match(/>\s*다운로드\s*</, response.body,
                    "목록에 파일을 주지 않는 «다운로드» 라벨이 남아 있다")
    assert_match(/미리보기·인쇄/, response.body)
  end

  # 음성 대조 — 미리보기 자체는 그대로 동작해야 한다(이번 변경으로 깨뜨리지 않았다).
  test "서식 미리보기 내용은 그대로 렌더된다" do
    get template_url(3)
    assert_response :success
    assert_match(/물품 검사검수조서/, response.body)
    assert_match(/HWP/, response.body, "파일 형식 표기는 유지된다")
  end
end
