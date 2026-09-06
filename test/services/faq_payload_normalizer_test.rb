# frozen_string_literal: true

require "test_helper"

# P2 R1 / P-1 — jsonb 에 갇힌 FAQ 복원기.
#
# 이 테스트의 목적은 "변환이 된다"가 아니라 **"안 되는 것을 안 된다고 하는가"** 다.
# 억지 복구는 곧 내용 창작이므로, 거부해야 하는 payload 를 거부하는지부터 고정한다.
class FaqPayloadNormalizerTest < ActiveSupport::TestCase
  # ── 양성대조: 진짜 깨진 payload 는 반드시 거부돼야 한다 ──
  # 이게 없으면 "전부 :ok" 를 돌려주는 껍데기 변환기도 이 스위트를 통과한다.
  BROKEN = {
    '[{"question"=>"a", "answer"=>}]' => :unparseable,
    "not json at all"                 => :unparseable,
    '{"question"=>"a"}'               => :not_array,
    '[{"question"=>"a"}]'             => :bad_shape,
    '[{"answer"=>"b"}]'               => :bad_shape,
    '[{"question"=>"", "answer"=>"b"}]' => :bad_shape,
    '[{"question"=>"a", "answer"=>""}]' => :bad_shape,
    '[{"q"=>"a", "a"=>"b"}]'          => :bad_shape,
    '["문자열만 들어있음"]'             => :bad_shape
  }.freeze

  BROKEN.each do |payload, expected|
    test "양성대조 — #{payload.truncate(38)} 는 #{expected} 로 거부된다" do
      status, = FaqPayloadNormalizer.call(payload)
      assert_equal expected, status, "복구 불가 payload 를 통과시키면 그 순간 내용 창작이 된다"
    end
  end

  # ── 음성대조: 정상은 통과해야 한다 ──
  test "이미 배열이면 손대지 않는다" do
    input = [ { "question" => "q", "answer" => "a" } ]
    status, value = FaqPayloadNormalizer.call(input)
    assert_equal :already_array, status
    assert_same input, value
  end

  test "JSON 문자열(이중 인코딩)은 배열로 복원된다" do
    status, value = FaqPayloadNormalizer.call('[{"question":"q","answer":"a"}]')
    assert_equal :ok, status
    assert_equal [ { "question" => "q", "answer" => "a" } ], value
  end

  test "Ruby inspect 문자열은 배열로 복원된다" do
    status, value = FaqPayloadNormalizer.call('[{"answer"=>"a", "question"=>"q"}]')
    assert_equal :ok, status
    assert_equal "q", value.first["question"]
    assert_equal "a", value.first["answer"]
  end

  test "여러 항목의 순서가 보존된다" do
    raw = '[{"answer"=>"a1", "question"=>"q1"}, {"answer"=>"a2", "question"=>"q2"}, {"answer"=>"a3", "question"=>"q3"}]'
    _, value = FaqPayloadNormalizer.call(raw)
    assert_equal %w[q1 q2 q3], value.map { |e| e["question"] }
  end

  # ── 경계: 답변 본문 안의 `=>` 는 구분자가 아니다 ──
  test "문자열 리터럴 안의 => 는 보존된다" do
    raw = '[{"answer"=>"조건 A => 결과 B 입니다", "question"=>"화살표 => 포함"}]'
    status, value = FaqPayloadNormalizer.call(raw)

    assert_equal :ok, status
    assert_equal "조건 A => 결과 B 입니다", value.first["answer"]
    assert_equal "화살표 => 포함", value.first["question"]
  end

  test "이스케이프된 따옴표가 문자열 상태를 깨뜨리지 않는다" do
    raw = '[{"answer"=>"그는 \"가능\"하다고 했다", "question"=>"q"}]'
    status, value = FaqPayloadNormalizer.call(raw)

    assert_equal :ok, status
    assert_equal '그는 "가능"하다고 했다', value.first["answer"]
  end

  test "문자열 밖의 nil 은 null 로 옮겨진다" do
    raw = '[{"answer"=>"a", "question"=>"q", "extra"=>nil}]'
    status, value = FaqPayloadNormalizer.call(raw)

    assert_equal :ok, status
    assert_nil value.first["extra"]
  end

  test "문자열 안의 nil 은 글자 그대로 남는다" do
    raw = '[{"answer"=>"nil 이라고 적혀 있다", "question"=>"q"}]'
    _, value = FaqPayloadNormalizer.call(raw)
    assert_equal "nil 이라고 적혀 있다", value.first["answer"]
  end

  # ── 내용 무변경 증명 ──
  test "복원 결과는 전부 원문의 부분문자열이다 — 변환은 내용을 만들지 않는다" do
    raw = '[{"answer"=>"추정가격에 따라 다릅니다", "question"=>"입찰공고 기간은?"}]'
    _, value = FaqPayloadNormalizer.call(raw)
    assert FaqPayloadNormalizer.preserves_source?(raw, value)
  end

  test "preserves_source? 는 원문에 없는 값을 걸러낸다" do
    raw = '[{"answer"=>"a", "question"=>"q"}]'
    fabricated = [ { "question" => "지어낸 질문", "answer" => "지어낸 답" } ]
    assert_not FaqPayloadNormalizer.preserves_source?(raw, fabricated)
  end

  # ── classify: lint·migration 이 쓰는 어휘 ──
  test "classify 는 저장 형태를 구분한다" do
    assert_equal :empty,             FaqPayloadNormalizer.classify(nil)
    assert_equal :empty,             FaqPayloadNormalizer.classify([])
    assert_equal :array_ok,          FaqPayloadNormalizer.classify([ { "question" => "q", "answer" => "a" } ])
    assert_equal :string_parseable,  FaqPayloadNormalizer.classify('[{"question":"q","answer":"a"}]')
    assert_equal :string_broken,     FaqPayloadNormalizer.classify('[{"answer"=>"a", "question"=>"q"}]')
    assert_equal :string_other,      FaqPayloadNormalizer.classify("not json at all")
  end

  test "authored_count 는 복구 가능한 payload 의 건수를 센다" do
    assert_equal 2, FaqPayloadNormalizer.authored_count('[{"answer"=>"a", "question"=>"q"}, {"answer"=>"b", "question"=>"r"}]')
    assert_equal 0, FaqPayloadNormalizer.authored_count("not json at all")
  end
end
