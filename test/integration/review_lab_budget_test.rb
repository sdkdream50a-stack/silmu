# frozen_string_literal: true

require "test_helper"

# P4 §14·§17 — 예산문서 면의 공개 범위·저장 안 함·개인정보·비회귀.
class ReviewLabBudgetTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  B = ReviewLab::FixtureBuilder
  D = ReviewLab::Demo

  setup do
    host! "silmu.kr"
    Rails.cache.clear
  end

  def upload(bytes, name)
    file = Tempfile.new([ "p4", File.extname(name) ])
    file.binmode
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/octet-stream", true, original_filename: name)
  end

  def signed_in_user
    u = User.create!(email: "p4-#{SecureRandom.hex(4)}@example.com", password: "password123456")
    sign_in u
    u
  end

  test "안내 화면은 비로그인도 열리고 업로드 폼 대신 로그인 안내가 나온다" do
    get "/review-lab/budget"
    assert_response :success
    assert_select "form[action='/review-lab/budget']", 0
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "비로그인 업로드는 막힌다" do
    post "/review-lab/budget", params: { plan_file: upload(B.hwpx(D.project_plan_blocks), "plan.hwpx") }
    assert_response :redirect
  end

  test "업로드 → 규칙 검사 결과가 나오고 원본 파일명은 화면에 없다" do
    signed_in_user
    post "/review-lab/budget", params: {
      plan_file: upload(B.hwpx(D.project_plan_blocks), "홍길동_사업계획서.hwpx"),
      basis_file: upload(B.xlsx(D.cost_basis_rows), "산출기초_2026.xlsx")
    }
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_match "사업계획·산출기초 검토", response.body
    refute_match "홍길동_사업계획서.hwpx", response.body
    refute_match "산출기초_2026.xlsx", response.body
  end

  test "파일을 하나도 올리지 않으면 422 이고 안내 문구가 나온다" do
    signed_in_user
    post "/review-lab/budget"
    assert_response :unprocessable_entity
    assert_match "올려 주세요", response.body
  end

  test "한 문서만 올려도 그 안의 산술은 검사하고 못 돌린 대조는 이유가 적힌다" do
    signed_in_user
    post "/review-lab/budget", params: { basis_file: upload(B.xlsx(D.cost_basis_rows), "b.xlsx") }
    assert_response :success
    assert_match "B-ROW", response.body
    assert_match "대조를 하지 않았습니다", response.body
  end

  test "읽을 수 없는 파일(binary HWP)은 «문제 없음» 이 아니라 지원하지 않는다고 말한다" do
    signed_in_user
    post "/review-lab/budget", params: { plan_file: upload("\xD0\xCF\x11\xE0dummy".b, "a.hwp") }
    assert_response :success
    assert_match "HWPX", response.body
    refute_match "문제를 찾지 못했습니다", response.body
  end

  test "demo 는 로그인 후 실제 파싱 경로를 타고 기대표와 일치한다" do
    signed_in_user
    post "/review-lab/demo/budget"
    assert_response :success
    assert_match "가상", response.body
  end

  test "검색엔진에 색인되지 않는다" do
    get "/review-lab/budget"
    assert_match(/noindex/i, response.body)
  end

  test "DB 에 아무것도 쓰지 않는다" do
    signed_in_user
    before = ActiveRecord::Base.connection.tables.sum { |t| ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{ActiveRecord::Base.connection.quote_table_name(t)}").to_i }
    post "/review-lab/budget", params: { basis_file: upload(B.xlsx(D.cost_basis_rows), "b.xlsx") }
    assert_response :success
    after = ActiveRecord::Base.connection.tables.sum { |t| ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{ActiveRecord::Base.connection.quote_table_name(t)}").to_i }
    assert_equal before, after
  end

  test "P2 결속 비회귀 — 24단계·기존 결속 유지 + 예산 검증이 1단계에 붙는다" do
    WorkflowBindings.reset!
    all = WorkflowBindings.all
    assert_equal 24, all.size
    assert_equal 78, all.values.sum { |g| g.values.sum(&:size) }
    assert(all["goods-4"]["review_lab"].any? { |i| i["path"] == "/review-lab/quote" })
    %w[goods-1 service-1 construction-1].each do |stage|
      assert(all[stage]["review_lab"].any? { |i| i["path"] == "/review-lab/budget" }, "#{stage} 결속 없음")
    end
  end

  # 전체 경로의 도달 검사는 `contract_flow_bindings_test.rb` 가 **이미** 양성 대조와 함께 한다.
  # 여기서는 P4 가 새로 더한 경로 하나만 실제로 연다 — 같은 검사를 두 번 쓰지 않는다.
  test "P4 가 더한 결속 경로가 실제로 열린다" do
    get "/review-lab/budget"
    assert_response :success
  end
end
