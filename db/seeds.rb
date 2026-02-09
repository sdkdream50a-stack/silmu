# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds/ 디렉토리의 시드 파일 로드 (의존 순서 보장)
# 1. topic_*.rb, topics.rb 먼저 (토픽 생성)
# 2. subtopics.rb (토픽에 의존)
# 3. 나머지 (audit_cases 등)

seed_dir = Rails.root.join("db/seeds")
seed_files = Dir[seed_dir.join("*.rb")].sort

# 토픽 파일을 먼저, subtopics를 그 다음, 나머지를 마지막으로
topic_files = seed_files.select { |f| File.basename(f).start_with?("topic") }
subtopic_files = seed_files.select { |f| File.basename(f) == "subtopics.rb" }
other_files = seed_files - topic_files - subtopic_files

(topic_files + subtopic_files + other_files).each do |seed_file|
  puts "📂 Loading #{seed_file.sub("#{Rails.root}/", '')}..."
  load seed_file
end
