# 여비 규정 설명 표 구기준 정정 (2026-09-17 전수감사 G-37 1차 후속)
#
# 20260917180000 적용 뒤 익명 조회로 domestic-travel-allowance 규정 탭에 직급별 일비·식비 표(20,000원)가 남은 것을 확인.
# 근거: 공무원 여비 규정 별표 2(2026.6.30. 개정) — 일비·식비 1일 각 25,000원(직급 차등 없음), 숙박비 실비·상한 서울 100,000·광역시 80,000·그 밖 70,000원.

from = "| 일비 | 출장 1일당 정액 (직급별 상이) |\n| 식비 | 출장 1일당 정액 (직급별 상이) |\n| 숙박비 | 실비 (상한액 범위 내) |\n\n#### 직급별 일비·식비 기준 (별표 2)\n\n| 직급 구분 | 일비 (1일) | 식비 (1일) |\n|---------|-----------|-----------|\n| 1~3급 (고위공무원) | 20,000원 | 25,000원 |\n| 4~5급 | 20,000원 | 25,000원 |\n| 6~9급, 기능직 | 25,000원 | 20,000원 |"
to = "| 일비 | 출장 1일당 정액 (직급 구분 없음) |\n| 식비 | 출장 1일당 정액 (직급 구분 없음) |\n| 숙박비 | 실비 (상한 서울 100,000원 · 광역시 80,000원 · 그 밖 70,000원) |\n\n#### 일비·식비 기준 (별표 2, 2026.6.30. 개정)\n\n| 구분 | 일비 (1일) | 식비 (1일) |\n|---------|-----------|-----------|\n| 모든 직급 | 25,000원 | 25,000원 |"

ActiveRecord::Base.transaction do
  topic = Topic.find_by!(slug: "domestic-travel-allowance")
  text = topic.regulation_content.to_s
  if text.include?(to) && !text.include?(from)
    puts "  [travel-table] changes=0"
  else
    raise "STALE_TABLE_NOT_FOUND" unless text.include?(from)

    topic.update_columns(regulation_content: text.sub(from, to), updated_at: Time.current) unless ENV["DRY_RUN"] == "1"
    puts "  [travel-table] #{ENV["DRY_RUN"] == "1" ? "DRY_RUN " : ""}changes=1"
  end
end
