# frozen_string_literal: true

require "test_helper"

# 정부조직 개편(2026-01-02) 반영 회귀 — 기획재정부 → 재정경제부(계약·국유재산·국고) / 기획예산처(예산·예비타당성조사).
class MinistryRenameTest < ActiveSupport::TestCase
  # 국외여비 카드는 공무원 여비 규정 별표 4(소관 인사혁신처)로 확인돼 2026-09-17 정정 — 예외 없음.
  ALLOWED = {}.freeze

  test "no stale 기획재정부/기재부 outside the reviewed exception" do
    counts = Dir[Rails.root.join("app/**/*.{rb,erb,js}")].to_h do |f|
      [ f.delete_prefix("#{Rails.root}/"), File.read(f).scan(/기획재정부|기재부/).size ]
    end.select { |_, n| n.positive? }
    assert_equal ALLOWED, counts
  end

  test "positive control: contract ministry and budget ministry are named correctly" do
    q1001 = ExamQuestions::QUESTIONS.find { |q| q[:id] == 1001 }
    assert_equal "국가계약법 — 재정경제부 / 지방계약법 — 행정안전부", q1001[:options][q1001[:correct]]
    assert_includes ExamQuestions::QUESTIONS.find { |q| q[:id] == 139 }[:explanation], "기획예산처"
  end
end
