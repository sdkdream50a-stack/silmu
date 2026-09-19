# frozen_string_literal: true

require "test_helper"

# 실무 검증실 Beta — 공개 범위·로그인·저장 안 함·로그 유출·비회귀.
class ReviewLabTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  B = ReviewLab::FixtureBuilder

  # 세션 쿠키 도메인이 .silmu.kr 이라 기본 테스트 호스트(www.example.com)에서는 두 번째 요청부터 로그인이 풀린다.
  setup { host! "silmu.kr" }

  def upload(bytes, name, type = "application/octet-stream")
    file = Tempfile.new([ "rl", File.extname(name) ])
    file.binmode
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, type, true, original_filename: name)
  end

  def quote_xlsx = B.xlsx(ReviewLab::Demo.quote_rows)

  # minitest 6 은 minitest/mock(stub)을 기본 번들에서 뺐다 — 의존성을 늘리지 않고 싱글턴 메서드를 잠시 바꾼다.
  def swap(klass, name, impl)
    original = klass.method(name)
    klass.define_singleton_method(name, &impl)
    yield
  ensure
    klass.define_singleton_method(name, original)
  end

  test "안내 화면은 비로그인도 열리고, 업로드 폼 대신 로그인 안내가 나온다" do
    %w[/review-lab /review-lab/quote /review-lab/package].each do |path|
      get path
      assert_response :success, path
      assert_includes response.body, "로그인하고 계속하기", path
      assert_not_includes response.body, 'type="file"', "#{path} — 비로그인에게 업로드 입력을 보이지 않는다"
      assert_includes response.body, "개인정보·민감정보는 제거 후 업로드하세요", path
      assert_includes response.body, "최종 행정·법률 판단은 담당자가 공식 근거를 확인해야 합니다", path
      assert_equal "no-store", response.headers["Cache-Control"], path
      assert_match(/noindex/, response.body, path)
    end
  end

  test "비로그인 업로드·검토·demo 는 차단되고 파일을 읽지 않는다" do
    swap(ReviewLab::TextExtractor, :call, ->(**) { flunk "비로그인 요청에서 파일을 읽었다" }) do
      post "/review-lab/quote", params: { main_file: upload(quote_xlsx, "q.xlsx") }
      assert_redirected_to new_user_session_path
      post "/review-lab/package", params: { files: { notice: upload(quote_xlsx, "a.xlsx"), spec: upload(quote_xlsx, "b.xlsx") } }
      assert_redirected_to new_user_session_path
      post "/review-lab/demo/quote"
      assert_redirected_to new_user_session_path
    end
  end

  test "로그인하면 업로드 폼과 외부 AI 고지(선택 항목 옆)가 보인다" do
    sign_in users(:one)
    get "/review-lab/quote"
    assert_includes response.body, 'type="file"'
    assert_includes response.body, "외부 AI(Anthropic)"
    assert_includes response.body, "판단과 확인은 담당자와 원문"
    get "/review-lab/package"
    %w[notice task_order spec].each { |role| assert_includes response.body, %(name="files[#{role}]") }
  end

  test "견적서 업로드 → 규칙 검사 보고서(원본 파일명은 화면에 쓰지 않는다)" do
    sign_in users(:one)
    post "/review-lab/quote", params: { main_file: upload(quote_xlsx, "홍길동_견적서.xlsx"), contract_type: "goods",
                                        agency_scope: "PUBLIC_SCHOOL", counterparty_type: "GENERAL" }
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    body = response.body
    assert_includes body, 'data-code="Q-ROW"'
    assert_includes body, 'data-severity="BLOCK"'
    assert_includes body, "계약방식·견적 요건"
    assert_includes body, "제25조"
    assert_not_includes body, "홍길동"
    assert_not_includes body, 'data-origin="ai"', "AI 를 선택하지 않았으면 AI 결과가 없다"
  end

  test "HWP 파일은 거절 사유와 변환 안내가 보고서에 나온다(검사 불가 · 통과 아님)" do
    sign_in users(:one)
    post "/review-lab/quote", params: { main_file: upload("\xD0\xCF\x11\xE0".b + ("\x00".b * 600), "q.hwp") }
    assert_response :success
    assert_includes response.body, "HWPX"
    assert_includes response.body, "검사하지 못한 항목"
    assert_not_includes response.body, 'data-severity="PASS"'
  end

  test "파일 없이 보내면 422 와 안내" do
    sign_in users(:one)
    post "/review-lab/quote", params: {}
    assert_response :unprocessable_entity
    assert_includes response.body, "견적서 파일을 올려 주세요"
    post "/review-lab/package", params: { files: { notice: upload(quote_xlsx, "a.xlsx") } }
    assert_response :unprocessable_entity
    assert_includes response.body, "2개 이상"
  end

  test "패키지 업로드 → 상호대조 행렬과 충돌" do
    sign_in users(:one)
    post "/review-lab/package", params: {
      files: { notice: upload(B.hwpx(ReviewLab::Demo.notice_blocks), "n.hwpx"),
               task_order: upload(B.docx(ReviewLab::Demo.task_order_blocks), "t.docx"),
               spec: upload(B.pdf(ReviewLab::Demo.spec_lines), "s.pdf", "application/pdf") },
      contract_type: "goods", agency_scope: "PUBLIC_SCHOOL"
    }
    assert_response :success
    assert_includes response.body, "문서 간 상호대조"
    assert_includes response.body, 'data-code="X-CONFLICT"'
    assert_includes response.body, 'data-code="P-35"'
  end

  test "demo 는 가상 문서 표시와 기대표 일치를 보여준다" do
    sign_in users(:one)
    %w[quote package].each do |kind|
      post "/review-lab/demo/#{kind}"
      assert_response :success
      assert_includes response.body, "가상 예시 문서입니다"
      assert_includes response.body, "빠진 것도, 더 나온 것도 없습니다", kind
    end
  end

  test "AI 의미검사는 선택했을 때만 돌고, 결과는 AI 라벨로 분리된다" do
    sign_in users(:one)
    calls = 0
    fake = ReviewLab::AiSemanticReviewer::Result.new(
      findings: [ ReviewLab::Finding.new(severity: "BLOCK", code: "AI-AMBIGUOUS", problem: "모호", origin: :ai) ], dropped: 0, error: nil
    )
    swap(ReviewLab::AiSemanticReviewer, :call, ->(**) { calls += 1; fake }) do
      post "/review-lab/demo/package"
      assert_equal 0, calls, "선택하지 않으면 외부 AI 를 부르지 않는다"
      post "/review-lab/demo/package", params: { use_ai: "1" }
      assert_equal 1, calls
    end
    assert_includes response.body, "AI 검토 · 추가 확인 필요"
    assert_includes response.body, 'data-origin="ai"'
    assert_includes response.body, 'data-severity="CHECK" data-code="AI-AMBIGUOUS" data-origin="ai"',
                    "AI 가 BLOCK 을 내도 화면에서는 CHECK 다"
  end

  test "로그에 원본 파일명·문서 내용이 남지 않는다" do
    sign_in users(:one)
    io = StringIO.new
    logger = ActiveSupport::Logger.new(io)
    old = Rails.logger
    Rails.logger = logger
    ActionController::Base.logger = logger
    begin
      post "/review-lab/quote", params: { main_file: upload(quote_xlsx, "홍길동_견적서.xlsx") }
    ensure
      Rails.logger = old
      ActionController::Base.logger = old
    end
    log = io.string
    assert_includes log, "ReviewLabController#quote_review", "양성 대조 — 로그가 실제로 잡혔다"
    assert_not_includes log, "홍길동"
    assert_not_includes log, "가나교육기자재"
    assert_includes log, "[FILTERED]"
  end

  test "학교 행정실 허브에서 검증실로 들어갈 수 있다" do
    get "/school-office"
    assert_includes response.body, 'href="/review-lab"'
  end

  test "도구 수 39 불변 — 검증실은 도구 레지스트리에 넣지 않는다" do
    assert_equal 39, ApplicationHelper::ACTIVE_TOOL_COUNT
    get "/tools"
    assert_not_includes response.body, "/review-lab/quote"
  end

  test "기존 견적서 검토 도구는 공개 그대로이고 검증실 링크가 붙었다" do
    get "/tools/quote-review"
    assert_response :success
    assert_includes response.body, "/review-lab/quote"
  end
end
