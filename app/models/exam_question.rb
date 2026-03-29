# 공공조달관리사 시험 문제 AR 모델
# exam_questions 테이블과 매핑 (기존 ExamQuestions 모듈 대체)
# options 컬럼: SQLite(text+JSON), PostgreSQL(text) 모두 호환
class ExamQuestion < ApplicationRecord
  serialize :options, coder: JSON

  scope :published, -> { where(published: true) }

  # 단일 문제 조회 (ExplanationsController용)
  # ExamQuestions.find_by_id(id) 대체
  def self.find_question(id)
    find_by(id: id)&.to_quiz_hash
  end

  # ID 배열로 문제 일괄 조회 (bookmark/wrong API용)
  # 반환 순서는 ids 입력 순서 보존
  def self.by_ids(ids)
    return [] if ids.blank?

    by_id = published.where(id: ids).index_by(&:id)
    ids.filter_map { |id| by_id[id.to_i]&.to_quiz_hash }
  end

  def to_quiz_hash
    {
      id: id,
      subject_id: subject_id,
      chapter_num: chapter_num,
      question: question,
      options: options,
      correct: correct,
      explanation: explanation,
      difficulty: difficulty
    }
  end
end
