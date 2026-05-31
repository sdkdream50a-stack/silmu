require "test_helper"

# 보기 결정적 셔플(정답 위치 편중 단서 제거)의 불변식 회귀 방지
class ExamQuestionsShuffleTest < ActiveSupport::TestCase
  test "정답 위치 분포가 4지선다에 고르게 분포(특정 번호 ≤35%)" do
    served = ExamQuestions.all_sliced_with_difficulty
    n = served.size
    dist = Hash.new(0)
    served.each { |q| dist[q[:correct]] += 1 }
    (0..3).each do |i|
      ratio = dist[i].to_f / n
      assert ratio <= 0.35, "정답 #{i + 1}번 비율 #{(ratio * 100).round(1)}% — 위치 단서 편중(≤35% 기대)"
    end
  end

  test "셔플 후에도 정답 내용이 보존된다" do
    orig = ExamQuestions::QUESTIONS.index_by { |q| q[:id] }
    ExamQuestions.all_sliced_with_difficulty.each do |q|
      o = orig[q[:id]]
      assert_equal o[:options][o[:correct]], q[:options][q[:correct]],
        "id=#{q[:id]} 셔플 후 정답 내용 불일치"
    end
  end

  test "셔플은 결정적(같은 id는 항상 같은 순서)" do
    a = ExamQuestions.shuffled_options(123, %w[a b c d], 1)
    b = ExamQuestions.shuffled_options(123, %w[a b c d], 1)
    assert_equal a, b
  end
end
