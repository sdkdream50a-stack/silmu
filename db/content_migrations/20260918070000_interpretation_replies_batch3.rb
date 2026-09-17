# 토픽 «질의·회신 예시» 탭 개별 검증 3차 — 원문과 다른 회신 정정 (2026-09-17 전수감사 G-38)
#
# 원문: 지방계약법 제30조의2·제31조·제34조, 같은 법 시행령 제92조·제110조, 같은 법 시행규칙 [별표 2](개정 2025. 7. 8.).
# 각 old 문자열은 현재 interpretation_content 에 정확히 1회 있어야 하고, 하나라도 없으면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.

edits = [
  [ "qualification-failure", "적격심사 결과에 이의가 있는 경우 탈락 통보 수령일로부터 10일 이내에 발주기관에 이의신청할 수 있습니다. 이의신청서에는 탈락 사유에 대한 반박 논거와 증빙 서류를 첨부하여야 합니다. 발주기관은 이의신청 접수 후 15일 이내에 검토 결과를 통보해야 하며, 이에도 불복할 경우 지방계약분쟁조정위원회에 조정을 신청하거나 행정심판·행정소송을 제기할 수 있습니다.", "낙찰자 결정과 관련하여 불이익을 받은 자는 불이익을 받은 날부터 20일 이내 또는 불이익을 받았음을 안 날부터 15일 이내에 해당 지방자치단체의 장에게 이의신청을 할 수 있습니다(「지방계약법」 제34조제1항제5호·제2항). 다만 이의신청 대상은 국제입찰 또는 시행령 제110조제1항의 규모(종합공사 추정가격 4억원, 전문공사 1억원, 그 밖의 공사 8천만원, 물품·용역 5천만원) 이상인 입찰에 의한 계약입니다. 지방자치단체의 장은 이의신청을 받은 날부터 15일 이내에 심사하여 필요한 조치를 하고 결과를 통지해야 하며(같은 조 제3항), 그 조치에 이의가 있으면 통지를 받은 날부터 20일 이내에 지방계약심의조정위원회에 재심을 청구할 수 있습니다(같은 조 제4항)." ],
  [ "qualification-failure", "허위 실적 제출은 「지방계약법」 제31조에 따른 부정당업자 제재 대상으로, 1년 이상 2년 이하의 입찰 참가 자격 정지 처분을 받습니다. 아울러 낙찰 취소 및 계약 해지, 계약보증금 몰수, 손해배상 청구가 가능합니다. 형사 고발 시 사기죄(공공계약 관련 위계에 의한 업무 방해)로도 처벌받을 수 있습니다.", "입찰에 관한 서류를 위조·변조·부정행사하거나 거짓 서류를 제출하여 낙찰을 받은 자는 「지방계약법」 제31조와 같은 법 시행령 제92조제2항제1호가목에 따른 입찰 참가자격 제한 대상이며, 제한기간은 11개월 이상 1년 1개월 미만입니다(같은 법 시행규칙 [별표 2] 제10호가목). 또한 입찰과정에서 거짓 서류를 제출하여 부당하게 낙찰을 받은 경우 낙찰자 결정을 취소하거나 계약을 해제 또는 해지할 수 있습니다(법 제30조의2제1항제3호). 형사 책임 여부는 수사기관과 법원이 판단합니다." ]
]

dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction do
  edits.group_by(&:first).each do |slug, list|
    topic = Topic.find_by(slug: slug)
    next unless topic

    text = topic.interpretation_content.to_s
    list.each do |_, old, new|
      next if text.include?(new) && !text.include?(old)
      raise "[g38-batch3] fingerprint missing: #{slug}" unless text.scan(old).size == 1

      text = text.sub(old) { new }
      changes += 1
    end
    topic.update_columns(interpretation_content: text, updated_at: Time.current) if text != topic.interpretation_content.to_s && !dry
  end
end
puts "  [g38-batch3] #{"DRY_RUN " if dry}changes=#{changes}"
