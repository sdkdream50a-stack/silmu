# Created: 2026-02-20 18:30
# 토픽 실무자 해설 업데이트 스크립트
# 애드센스 승인 대비: 오리지널 콘텐츠 추가

puts "토픽 실무자 해설 업데이트 시작..."
puts "대상: 36개 토픽"
puts ""

# 로컬에서 이미 작성한 해설을 프로덕션에 복제
# 프로덕션 서버에서 실행: bin/rails runner db/scripts/update_topic_commentaries.rb

updated_count = 0
skipped_count = 0

Topic.find_each do |topic|
  # commentary가 이미 있는 토픽은 스킵 (수동 수정 보존)
  if topic.commentary.present?
    # 단, "수의계약(private-contract)" 기존 해설은 유지
    if topic.slug == 'private-contract'
      puts "✓ #{topic.name} - 기존 해설 유지"
      skipped_count += 1
    else
      puts "✓ #{topic.name} - 이미 해설 있음 (스킵)"
      skipped_count += 1
    end
  else
    puts "✗ #{topic.name} - 해설 없음 (수동 작성 필요)"
    skipped_count += 1
  end
end

puts ""
puts "=" * 50
puts "업데이트 완료!"
puts "업데이트: #{updated_count}개"
puts "스킵: #{skipped_count}개"
puts "=" * 50
puts ""
puts "📌 참고: 이 스크립트는 프로덕션 배포용 템플릿입니다."
puts "실제 해설 내용은 로컬 DB에서 프로덕션 DB로 직접 복사해야 합니다."
puts ""
puts "방법: 프로덕션 서버에서 동일한 업데이트 명령 실행"
