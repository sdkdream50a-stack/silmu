# 퇴직수당 토픽 «관련 예규·지침» 탭 정정 (2026-09-17 전수감사 G-36/G-38 잔여)
#
# 운영 본문은 원문을 확인할 수 없는 예규·지침 3건을 싣고, 존재하지 않는 법령명 «공무원 퇴직급여법»을 인용했다.
# 내용도 공무원연금법과 달랐다(파면·해임 «지급 제외» ↔ 제65조 일부 감액, «지자체 충당금 지급», 합산 반납 «이자 가산 안 함» ↔ 제26조②).
# 원문: 공무원연금법 제25조·제26조·제62조·제65조(law.go.kr). 현재 본문 sha256 이 감사 시점과 같을 때만 교체한다. DRY_RUN=1 이면 쓰지 않는다.

fingerprint = "63a5ccfd83d91c0046b3184cf5278312d7d4ffed59335f5239a29b87987a3ccd"
replacement = <<~MD.strip
  ## 관련 법령 요지

  - **퇴직수당 지급**: 공무원이 1년 이상 재직하고 퇴직하거나 사망한 경우 퇴직수당을 지급한다(「공무원연금법」 제62조제1항). 금액은 같은 조 제2항의 계산식에 따른다.
  - **급여의 제한**: 탄핵 또는 징계에 의하여 파면된 경우, 금품 및 향응 수수·공금의 횡령·유용으로 징계에 의하여 해임된 경우 등에는 퇴직급여 및 퇴직수당의 일부를 줄여 지급한다(제65조제1항). 감액 사유가 소급하여 소멸하면 감액된 금액에 이자를 가산하여 지급한다(같은 조 제2항).
  - **재직기간 합산**: 퇴직한 공무원 등이 다시 임용되면 본인이 원하는 바에 따라 종전 재직기간을 합산할 수 있고(제25조제2항), 합산을 인정받으면 퇴직 당시 받은 퇴직급여액에 이자를 가산하여 반납한다(제26조제2항). 반납금을 분할하여 내는 경우에도 이자를 가산한다(같은 조 제3항). 이렇게 합산한 재직기간은 퇴직수당을 지급할 때에는 재직기간에 합산하지 않는다(제25조제4항).

  출처: 국가법령정보센터(law.go.kr) 「공무원연금법」
MD

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction do
  topic = Topic.find_by(slug: "retirement-allowance")
  if topic && topic.regulation_content.to_s != replacement
    raise "[retirement-regulation] fingerprint missing" unless Digest::SHA256.hexdigest(topic.regulation_content.to_s) == fingerprint

    topic.update_columns(regulation_content: replacement, updated_at: Time.current) unless dry
    changes += 1
  end
end
puts "  [retirement-regulation] #{"DRY_RUN " if dry}changes=#{changes}"
