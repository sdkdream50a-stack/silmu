namespace :task_guides do
  desc "기본 업무 80여개의 AI 프로세스 가이드 일괄 생성"
  task generate_all: :environment do
    unless ENV["ANTHROPIC_API_KEY"].present?
      puts "❌ ANTHROPIC_API_KEY 환경변수가 설정되지 않았습니다."
      exit 1
    end

    # 업무달력 기본 업무 목록
    tasks = [
      { title: "원천세 신고·납부", cat: "세무" },
      { title: "4대보험료 납부", cat: "보험" },
      { title: "급여 지급 준비 (공제내역 확인)", cat: "급여" },
      { title: "급여 지급 준비", cat: "급여" },
      { title: "급여 지급", cat: "급여" },
      { title: "일용근로소득 지급명세서 제출", cat: "보고" },
      { title: "연말정산 간소화 자료 확인·제출", cat: "세무" },
      { title: "전년도 세입·세출 결산 마감", cat: "회계" },
      { title: "건강보험 정산(보수총액 신고)", cat: "보험" },
      { title: "연말정산 환급·추징 처리", cat: "세무" },
      { title: "4대보험 사업장현황 신고", cat: "보고" },
      { title: "세입 세출 예산 관련", cat: "서무" },
      { title: "근로소득 지급명세서 제출", cat: "보고" },
      { title: "고용·산재보험 보수총액 신고", cat: "보험" },
      { title: "1분기 결산 준비", cat: "회계" },
      { title: "건강보험 연말정산 보험료 반영", cat: "보험" },
      { title: "상반기 물품구매계획 점검", cat: "서무" },
      { title: "지방세 납부(면허세 등)", cat: "세무" },
      { title: "1분기 업무 실적 보고", cat: "보고" },
      { title: "맞춤형복지 상반기 사용 점검", cat: "복지" },
      { title: "종합소득세 신고(해당 시)", cat: "세무" },
      { title: "상반기 계약 집행 현황 보고", cat: "보고" },
      { title: "상반기(2분기) 결산", cat: "회계" },
      { title: "하반기 업무계획 수립", cat: "서무" },
      { title: "재산세 납부(건축물)", cat: "세무" },
      { title: "건강보험 보수월액 변경신고", cat: "보험" },
      { title: "상반기 업무 실적 보고", cat: "보고" },
      { title: "주민세(사업소분) 신고·납부", cat: "세무" },
      { title: "하반기 물품구매계획 점검", cat: "서무" },
      { title: "재산세 납부(토지)", cat: "세무" },
      { title: "2분기 업무 실적 보고", cat: "보고" },
      { title: "맞춤형복지 하반기 사용 점검", cat: "복지" },
      { title: "하반기 보험료 정산 준비", cat: "보험" },
      { title: "3분기 업무 실적 보고", cat: "보고" },
      { title: "3분기 결산 준비", cat: "회계" },
      { title: "연말정산 사전 안내", cat: "세무" },
      { title: "4대보험 연말 정산 준비", cat: "보험" },
      { title: "맞춤형복지 잔여포인트 소진 안내", cat: "복지" },
      { title: "하반기 업무 실적 보고", cat: "보고" },
      { title: "연간 결산·마감 준비", cat: "회계" },
      { title: "다음연도 예산 요구서 작성", cat: "회계" }
    ].uniq { |t| t[:title] }

    service = TaskGuideService.new
    total = tasks.size
    skipped = 0
    generated = 0
    failed = 0

    tasks.each_with_index do |task, idx|
      existing = TaskGuide.find_by(task_title: task[:title])
      if existing&.completed?
        skipped += 1
        puts "⏭️  [#{idx + 1}/#{total}] #{task[:title]} — 이미 생성됨"
        next
      end

      print "🔄 [#{idx + 1}/#{total}] #{task[:title]}..."
      guide = service.generate(task[:title], task[:cat])

      if guide&.completed?
        generated += 1
        puts " ✅ 완료"
      else
        failed += 1
        puts " ❌ 실패"
      end

      sleep 0.5  # Rate limit 방지
    end

    puts "\n📊 결과: 총 #{total}건 중 생성 #{generated}건, 건너뜀 #{skipped}건, 실패 #{failed}건"
  end
end
