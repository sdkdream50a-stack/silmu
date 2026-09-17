# 명절휴가비 지급기준일 잔존 정정 (2026-09-17 전수감사 G-37 2차 후속)
#
# 20260917210000 적용 뒤 익명 조회로 decree_content·rule_content 에 «기준일(전월 말일)»이 남은 것을 확인.
# 원문: 공무원수당 등에 관한 규정 제18조의3 ① 설날 및 추석날(지급기준일) 현재 재직 중인 공무원에게 지급
#       ② 지급기준일 현재 월봉급액의 60퍼센트.

subs = [
  [ :decree_content, "| 기준일(전월 말일) 재직 중인 경우 | 전액 지급 |", "| 지급기준일(설날·추석날) 현재 재직 중인 경우 | 전액 지급 |" ],
  [ :rule_content, "- 기준일(전월 말일) 현재의 봉급월액 적용", "- 지급기준일(설날·추석날) 현재의 월봉급액 적용 (제18조의3 제2항)" ]
]

ActiveRecord::Base.transaction do
  topic = Topic.find_by!(slug: "holiday-bonus")
  changed = 0
  subs.each do |column, from, to|
    text = topic.public_send(column).to_s
    next if text.include?(to) && !text.include?(from)
    raise "STALE_TEXT_NOT_FOUND #{column}" unless text.include?(from)

    topic.update_columns(column => text.sub(from, to), updated_at: Time.current) unless ENV["DRY_RUN"] == "1"
    changed += 1
  end
  puts "  [holiday-basis] #{ENV['DRY_RUN'] == '1' ? 'DRY_RUN ' : ''}changes=#{changed}"
end
