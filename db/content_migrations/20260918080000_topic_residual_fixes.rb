# 토픽 잔여 정정 — 회계관계직원 탭(없는 법령명·예규) · 여비 탭 없는 법령명 · 특별휴가 질의 전제 (2026-09-17 전수감사 G-44·G-38)
#
# accounting-officers regulation_content: «회계관계공무원 등의 책임에 관한 법률»(실제 «회계관계직원 등의 책임에 관한 법률»), 원문 미확인 «회계관계공무원 운영지침»,
#   «경과실 감면 가능»(제4조①은 고의·중과실 요건) · «감사원 심사청구»(감사원법 제36조 재심의) → 법령 요지로 교체(sha256 일치 시).
# travel-expense: 없는 «지방공무원 여비규정» 문장 교체. special-leave: 회신 정정(20260918040000) 후에도 남은 질의 전제 «5일이라면» 교체.
# 하나라도 지문이 맞지 않으면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.

replacements = [
  [ "accounting-officers", "418aa285439a8fcb9e5612d64ad873f95bbd8655f67fe7e2d0d9fad2b86b73e5", "## 관련 법령 요지\n\n- **회계관계직원의 범위**: 「회계관계직원 등의 책임에 관한 법률」 제2조는 국가의 회계사무를 집행하는 수입징수관·재무관·지출관·계약관·현금출납 공무원, 물품관리관·물품운용관·물품출납 공무원 등과, 「지방재정법」·「지방회계법」 등에 따라 지방자치단체의 회계사무를 집행하는 징수관·재무관·지출원·출납원·물품관리관·물품 사용 공무원 등, 그리고 이들의 대리자·분임자와 보조자를 회계관계직원으로 정한다.\n- **변상책임**: 고의 또는 중대한 과실로 법령이나 관계 규정 및 예산에 정하여진 바를 위반하여 재산에 손해를 끼친 경우 변상할 책임이 있고(제4조제1항), 현금 또는 물품을 출납·보관하는 회계관계직원은 선량한 관리자로서의 주의를 게을리하여 보관 중인 현금·물품이 망실·훼손된 경우 변상할 책임이 있다(같은 조 제2항). 2명 이상의 행위로 손해가 생기면 각자의 행위가 손해발생에 미친 정도에 따라 책임을 진다(같은 조 제4항).\n- **감면**: 감사원은 변상금액을 정할 때 제5조 각 호의 사유가 있으면 전부 또는 일부를 감면할 수 있으나, 고의에 의한 손해는 감면하지 않는다(제5조).\n- **판정 전 변상명령과 불복**: 중앙관서의 장·지방자치단체의 장 등은 감사원 판정 전이라도 변상을 명할 수 있고, 변상명령에 이의가 있으면 감사원에 판정을 청구할 수 있다(제6조제1항·제3항). 감사원의 변상 판정에 대해서는 변상판정서가 도달한 날부터 3개월 이내에 재심의를 청구할 수 있다(「감사원법」 제36조제1항).\n- **위법한 지시**: 상급자가 위법한 회계관계행위를 지시·요구하여 손해가 생기면 상급자는 회계관계직원과 연대하여 변상책임을 지며, 회계관계직원은 그 지시를 서면 등으로 이유를 밝혀 거부해야 한다(제8조).\n\n출처: 국가법령정보센터(law.go.kr) 「회계관계직원 등의 책임에 관한 법률」·「감사원법」" ]
]
substitutions = [
  [ "travel-expense", :regulation_content, "- 지방공무원: 「지방공무원 여비규정」 적용 (유사 구조)", "- 지방공무원: 소속 지방자치단체의 여비 조례·규칙을 확인" ],
  [ "special-leave", :interpretation_content, "조부모 사망 특별휴가가 5일이라면, 외조부모(외할아버지·외할머니)도 동일하게 5일인지", "조부모 사망 경조사휴가와 외조부모(외할아버지·외할머니) 사망 경조사휴가의 일수가 같은지" ]
]

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction do
  replacements.each do |slug, fingerprint, replacement|
    topic = Topic.find_by(slug: slug)
    next if topic.nil? || topic.regulation_content.to_s == replacement
    raise "[topic-residual] fingerprint missing: #{slug}" unless Digest::SHA256.hexdigest(topic.regulation_content.to_s) == fingerprint

    topic.update_columns(regulation_content: replacement, updated_at: Time.current) unless dry
    changes += 1
  end
  substitutions.each do |slug, column, old, new|
    topic = Topic.find_by(slug: slug)
    next unless topic

    text = topic.public_send(column).to_s
    next if text.include?(new) && !text.include?(old)
    raise "[topic-residual] fingerprint missing: #{slug}/#{column}" unless text.scan(old).size == 1

    topic.update_columns(column => text.sub(old) { new }, updated_at: Time.current) unless dry
    changes += 1
  end
end
puts "  [topic-residual] #{"DRY_RUN " if dry}changes=#{changes}"
