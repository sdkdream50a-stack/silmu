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

# 챕터별 ID 정렬 기준 난이도 계산 (ExamQuestions::DIFFICULTY_MAP 로직 복제)
# 챕터 내 하위 60% = "basic", 상위 40% = "advanced"
chapter_ids = {}
ExamQuestions::QUESTIONS.each do |q|
  key = "#{q[:subject_id]}-#{q[:chapter_num]}"
  (chapter_ids[key] ||= []) << q[:id]
end
chapter_ids.each_value(&:sort!)

difficulty_map = {}
chapter_ids.each do |_key, ids|
  threshold = (ids.size * 0.6).ceil
  ids.each_with_index do |id, idx|
    difficulty_map[id] = idx < threshold ? "basic" : "advanced"
  end
end

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
      options: q[:options].to_json,
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
