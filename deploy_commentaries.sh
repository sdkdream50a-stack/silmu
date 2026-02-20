#!/bin/bash
# 프로덕션 서버에 토픽 해설 배포

echo "프로덕션 서버에 토픽 해설 배포 중..."

# 로컬에서 작성한 해설을 프로덕션으로 전송
# 방법: 로컬 DB → SQL 덤프 → 프로덕션 DB 업데이트

# 1. 로컬 DB에서 commentary 데이터만 추출
bin/rails runner "
  File.open('tmp/commentaries.sql', 'w') do |f|
    Topic.where.not(commentary: nil).each do |t|
      commentary_escaped = t.commentary.gsub(\"'\", \"''\")
      f.puts \"UPDATE topics SET commentary = '#{commentary_escaped}' WHERE slug = '#{t.slug}';\"
    end
  end
  puts 'SQL 파일 생성 완료: tmp/commentaries.sql'
"

echo ""
echo "SQL 파일 생성 완료!"
echo ""
echo "다음 단계:"
echo "1. tmp/commentaries.sql 파일을 프로덕션 서버로 전송"
echo "2. 프로덕션 DB에서 SQL 실행"
echo ""
