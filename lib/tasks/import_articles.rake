require "csv"

namespace :articles do
  desc "네이버 카페 게시글 CSV 데이터 import"
  task import: :environment do
    csv_path = ENV["CSV_PATH"] || Rails.root.join("db", "cafe_articles.csv")

    unless File.exist?(csv_path)
      puts "❌ CSV 파일을 찾을 수 없습니다: #{csv_path}"
      puts "사용법: rails articles:import CSV_PATH=/path/to/file.csv"
      exit 1
    end

    puts "📥 CSV 파일 읽는 중: #{csv_path}"

    count = 0
    errors = 0

    CSV.foreach(csv_path, headers: true, encoding: "bom|utf-8") do |row|
      begin
        # 날짜 파싱
        written_at = begin
          DateTime.parse(row["작성일시"].to_s.gsub(".", "-").gsub(" ", ""))
        rescue
          nil
        end

        CafeArticle.find_or_create_by(article_id: row["게시글ID"].to_i) do |article|
          article.title = row["제목"]
          article.author = row["작성자"]
          article.board = row["게시판"]
          article.written_at = written_at
          article.view_count = row["조회수"].to_i
          article.comment_count = row["댓글수"].to_i
          article.like_count = row["좋아요수"].to_i
          article.url = row["게시글URL"]
        end

        count += 1
        print "\r📥 #{count}개 처리 중..." if count % 100 == 0
      rescue => e
        errors += 1
        puts "\n⚠️ 에러 (row #{count}): #{e.message}"
      end
    end

    puts "\n✅ 완료! #{count}개 게시글 import, #{errors}개 에러"
    puts "📊 총 게시글 수: #{CafeArticle.count}개"
  end

  desc "게시글 통계 출력"
  task stats: :environment do
    puts "📊 게시글 통계"
    puts "=" * 50
    puts "총 게시글 수: #{CafeArticle.count}개"
    puts "\n【게시판별 게시글 수】"
    CafeArticle.board_list.first(15).each do |board, count|
      puts "  #{board}: #{count}개"
    end
  end
end
