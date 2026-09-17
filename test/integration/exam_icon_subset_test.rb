# frozen_string_literal: true

require "test_helper"

# 전수감사 UX TOP#9 (exam) — exam 은 Material Symbols 폰트를 `icon_names=` 서브셋으로 받는다.
# 서브셋에 없는 이름은 리거처가 안 돼 잘린 글자("ƆM")로 보인다. 뷰·JS 가 쓰는 이름 ⊆ 서브셋을 강제한다.
class ExamIconSubsetTest < ActiveSupport::TestCase
  LAYOUT = Rails.root.join("app/views/layouts/exam.html.erb")
  SOURCES = %w[
    app/views/exam/**/*.erb
    app/views/layouts/*exam*.erb
    app/javascript/controllers/exam_*.js
  ].freeze

  def subset
    File.read(LAYOUT)[/icon_names=([a-z0-9_,]+)/, 1].to_s.split(",")
  end

  def used_icons
    SOURCES.flat_map { |g| Dir[Rails.root.join(g)] }.each_with_object({}) do |f, acc|
      src = File.read(f)
      names = src.scan(/material-symbols-outlined[^>]*>\s*([a-z][a-z0-9_]*)\s*</).flatten
      names += src.scan(/icon:\s*["']([a-z][a-z0-9_]*)["']/).flatten
      names.each { |n| (acc[n] ||= []) << f.to_s.delete_prefix("#{Rails.root}/") }
    end
  end

  test "exam 서브셋은 정렬돼 있고 비어 있지 않다" do
    assert_operator subset.size, :>, 50
    assert_equal subset.sort, subset, "Google Fonts icon_names 는 알파벳순이어야 한다"
  end

  test "exam 뷰·JS 가 쓰는 아이콘 이름은 모두 폰트 서브셋에 있다" do
    missing = used_icons.reject { |name, _| subset.include?(name) }
    assert_empty missing, "서브셋 누락: #{missing.map { |n, fs| "#{n} (#{fs.uniq.join(', ')})" }.join('; ')}"
  end

  test "과목 데이터의 아이콘도 서브셋에 있다" do
    icons = ExamQuestions::EXAM_SUBJECTS.map { |s| s[:icon] }.compact
    assert_not_empty icons
    assert_empty icons - subset
  end
end
