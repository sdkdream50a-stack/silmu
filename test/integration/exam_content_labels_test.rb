# frozen_string_literal: true

require "test_helper"

# 시험 콘텐츠 라벨·G-15 잔여 회귀 (2026-09-17 전수감사 16_EXAM_G15_LABEL_AUDIT A·B·C·D).
# 원문: 정부 입찰·계약 집행기준 제10조의2①(소액수의 견적 88%) · 지방 집행기준 제5장(2천만원 이하 90%) ·
# 조달청 물품구매적격심사 세부기준 제9조①(종합평점 85점) · 국가계약법 시행령 제42조①③.
# 제1회 필기(2026.10.03) 전이므로 기출은 존재하지 않는다 — 자체 문항·예측을 공식·기출처럼 표시하지 않는다.
class ExamContentLabelsTest < ActionDispatch::IntegrationTest
  SCAN_GLOBS = %w[
    app/views/exam/**/* app/controllers/exam/**/* app/models/exam_*.rb app/models/exam_curriculum/**/*
  ].freeze
  FORBIDDEN = /기출 유형|실제 출제 예시|확실합니다|1,500\+|200문항|조달청 공시/

  def scanned_files
    SCAN_GLOBS.flat_map { |g| Dir[Rails.root.join(g)] }.select { |f| File.file?(f) }
  end

  def practical(id) = ExamPracticalQuestions::QUESTIONS.find { |q| q[:id] == id }

  test "NORMAL: 시험 코드 전체에 기출·확정·근거 불명 수량 문구가 없다 (스캔 대상이 실제로 존재)" do
    files = scanned_files
    assert_operator files.size, :>, 20, "양성대조: glob 이 파일을 잡는다"
    assert_match FORBIDDEN, "공무원을 위한 기출 유형 분석", "양성대조: 패턴이 옛 문구를 잡는다"
    hits = files.flat_map do |f|
      File.readlines(f).each_with_index.select { |line, _| line.match?(FORBIDDEN) }
          .map { |line, i| "#{f.delete_prefix("#{Rails.root}/")}:#{i + 1}: #{line.strip[0, 80]}" }
    end
    assert_empty hits, "금지 문구 잔존:\n#{hits.join("\n")}"
  end

  test "EDGE: 실기 6번 hint·모범답안에 근거 없는 88점이 없고 공사 95점·조달청 물품 85점을 구분한다 (A-14·A-15)" do
    q = practical(6)
    assert_not_includes q[:answer_hint], "88점"
    assert_includes q[:answer_hint], "공사 95점"
    assert_includes q[:model_answer], "종합평점 95점 이상"
    assert_includes q[:model_answer], "조달청 물품: 종합평점 85점 이상(조달청 물품구매적격심사 세부기준 제9조①)"
  end

  test "LOWER_BOUND: 낙찰자 결정 비교표에 87%·일반 공사 최저가가 없다 (A-16·A-18·A-19)" do
    s2 = Rails.root.join("app/models/exam_curriculum/subject2.rb").read
    s3 = Rails.root.join("app/models/exam_curriculum/subject3.rb").read
    assert_not_includes s2, "예정가격의 87% 이상"
    assert_includes s2, "물품·용역: 예정가격의 88% 이상"
    assert_not_includes s2, '"일반 물품·공사"'
    assert_includes s2, "시행령 제42조③"
    assert_not_includes s3, "최저가낙찰제: 소액 물품 — 예정가격 이하 최저가 업체 낙찰"
    assert_includes s3, "하한 없는 최저가 낙찰이 아님"
    # NEEDS_REVIEW(A-17)는 원문 미확인이라 그대로 둔다
    assert_includes s2, "**88~95%** (금액별 차등)"
  end

  test "UPPER_BOUND: 페이지마다 성격 배지가 붙고 수량·일정은 정본에서 온다" do
    host! "exam.silmu.kr"
    {
      "/exam-strategy" => "실무.kr 예측",
      "/exam-info" => "공식 · 큐넷",
      "/practical" => "실무.kr 자체 문항",
      "/keywords" => "실무.kr 자체 문항",
      "/subjects/1/chapters/1" => "표준교재 요약"
    }.each do |path, label|
      get path
      assert_response :success, path
      assert_includes response.body, %(data-content-badge="#{ExamHelper::CONTENT_BADGES.key(label)}"), path
      assert_includes response.body, label, path
    end
    get "/subjects/1/chapters/1"
    assert_includes response.body, "출제 예상 포인트"
    assert_not_includes response.body, "시험 출제 포인트"

    get "/"
    assert_response :success
    assert_includes response.body, "#{ActiveSupport::NumberHelper.number_to_delimited(ExamQuestions::QUESTIONS.size / 100 * 100)}+"
    assert_includes response.body, ExamSchedule::SOURCE_NAME
    assert_includes response.body, "공공조달과 법제도 이해"
    assert_not_includes response.body, "2026년 (예정)"
    assert_not_includes response.body, "첫 시험 합격이 가능합니다"
  end

  test "EXCEPTION: 해설 5건의 출제 빈도 단정이 사라지고 정답 인덱스는 그대로다, 모르는 배지 종류는 거부한다" do
    expected_correct = { 1 => 1, 2 => 2, 7 => 2, 1004 => 1, 1009 => 2 } # origin/main a1c9ff9 값
    touched = ExamQuestions::QUESTIONS.select { |q| expected_correct.key?(q[:id]) }
    assert_equal 5, touched.size
    touched.each do |q|
      assert_no_match(/빈출|자주 출제|출제됩니다/, q[:explanation], "id #{q[:id]}")
      assert_equal expected_correct[q[:id]], q[:correct], "id #{q[:id]} 정답 인덱스 불변"
    end
    assert_raises(KeyError) { ApplicationController.helpers.content_badge(:official_exam) }
  end
  test "NORMAL (풀이 화면): 문제 풀이 화면(모의고사·미니 퀴즈·실전 모드)에 자체 문항 라벨이 붙는다" do
    %w[app/views/exam/quizzes/index.html.erb app/views/exam/quizzes/mini.html.erb
       app/views/exam/quizzes/show.html.erb app/views/exam/quizzes/simulation.html.erb].each do |f|
      assert_includes File.read(Rails.root.join(f)), "content_badge(:practice)", f
    end
  end
end
