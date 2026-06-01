# 공공조달관리사 시험 문제 DB 시딩
# ExamQuestions::QUESTIONS 배열 → exam_questions 테이블 이관
#
# 중요: 기존 ID 보존 필수
#   exam_progresses.bookmarks / wrong_answers 컬럼에 문제 ID가 저장되어 있어
#   ID가 바뀌면 사용자의 북마크/오답 데이터가 깨짐
#
# 실행 방법:
#   로컬:   rails runner db/seeds/exam_questions_seed.rb
#   운영:   docker exec <container> bin/rails runner db/seeds/exam_questions_seed.rb

puts "exam_questions 시딩 시작..."

# 난이도는 ExamQuestions::DIFFICULTY_MAP(문항 내용 기반 휴리스틱)을 그대로 사용
# — 종전 ID 위치 기반 로직 복제본은 모듈과 어긋나므로 폐기
difficulty_map = ExamQuestions::DIFFICULTY_MAP

ExamQuestion.transaction do
  # 멱등성: 재실행 시 기존 데이터 초기화 후 재삽입
  ExamQuestion.delete_all

  now = Time.current
  records = ExamQuestions::QUESTIONS.map do |q|
    {
      id: q[:id],
      subject_id: q[:subject_id],
      chapter_num: q[:chapter_num],
      question: q[:question],
      options: q[:options], # serialize coder: JSON이 insert_all!에서 1회 인코딩 (.to_json 시 이중인코딩)
      correct: q[:correct],
      explanation: q[:explanation].to_s,
      difficulty: difficulty_map[q[:id]] || "basic",
      published: true,
      created_at: now,
      updated_at: now
    }
  end

  # 100개 단위 배치 삽입
  inserted = 0
  records.each_slice(100) do |batch|
    ExamQuestion.insert_all!(batch)
    inserted += batch.size
    print "  #{inserted}/#{records.size} 삽입 중...\r"
  end
end

# PostgreSQL 시퀀스 리셋 (수동 ID 삽입 후 다음 auto_increment 충돌 방지)
if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  ActiveRecord::Base.connection.execute(
    "SELECT setval('exam_questions_id_seq', (SELECT MAX(id) FROM exam_questions))"
  )
  puts "  PostgreSQL 시퀀스 리셋 완료"
end

count = ExamQuestion.count
puts "exam_questions 시딩 완료: #{count}개 문제"
