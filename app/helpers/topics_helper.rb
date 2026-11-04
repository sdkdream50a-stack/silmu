module TopicsHelper
  # 계약 토픽 57개가 같은 수의계약 서식 4개를 반복했다(2026-11-04 운영 실측). 쓰임이 맞는 토픽에만 붙인다.
  TOPIC_FORMS = {
    reason: { title: "수의계약 사유서", desc: "수의계약 체결 사유를 명시하는 서류", badge: "별지 제5호 서식", color: "indigo", path: "/forms/수의계약사유서.html" },
    quote: { title: "견적서", desc: "업체로부터 징구하는 가격 견적서", badge: "1인/2인 이상 견적용", color: "emerald", path: "/forms/견적서.html" },
    price: { title: "예정가격 조서", desc: "예정가격 산출 근거 문서", badge: "거래실례가격/원가계산", color: "amber", path: "/forms/예정가격조서.html" },
    inspection: { title: "검수조서", desc: "납품/용역 완료 검수 확인서", badge: "대금지급 전 확인", color: "blue", path: "/forms/검수조서.html" }
  }.freeze

  TOPIC_FORM_KEYS = {
    %w[private-contract private-contract-amount private-contract-justification private-contract-limit small-amount-contract] => %i[reason quote price inspection],
    %w[emergency-contract single-quote dual-quote] => %i[reason quote],
    %w[quote-collection-guide] => %i[quote],
    %w[estimated-price estimated-amount cost-calculation-guide multiple-price] => %i[price],
    %w[inspection construction-completion completion-payment-checklist payment] => %i[inspection]
  }.flat_map { |slugs, keys| slugs.map { |slug| [ slug, keys ] } }.to_h.freeze

  def topic_form_cards(slug)
    TOPIC_FORM_KEYS.fetch(slug, []).map { |key| TOPIC_FORMS.fetch(key) }
  end

  # 유권해석 탭 신뢰 표시 (2026-09-17 전수감사 G-38).
  # 운영 토픽 93개 해석 탭 중 원문을 확인한 공식 회신은 0건이고, 문서번호가 적힌 7건도 서로 다른 질의에 같은 번호
  # («계약제도과-2891»·«-3102» 각 2회)를 써서 번호 존재가 근거가 되지 못한다. 원문 확인 체계가 생기기 전까지 전부 예시로 표시한다.
  # F1 containment (2026-10-05 · silmu-project-main-1005): 운영 질의·회신 347건 전수 대조 결과 공식 회신으로 확인된 것 0건,
  # 확인 불가 문서번호·기관 회신 표기 243건, 법령과 어긋나거나 낡은 주장 30건(예: 지체상금 «증액» 소송 — 민법 제398조는 감액만).
  # 면책 문구로는 공식 근거처럼 보이는 표기를 지우지 못하므로, 정정(owner 결정 B)이 끝날 때까지 탭을 공개하지 않는다.
  # DB 데이터는 그대로 둔다. 되돌리기 = SILMU_INTERPRETATION_TAB=on (재배포 시 env) 또는 이 메서드.
  def interpretation_tab_public?
    ENV["SILMU_INTERPRETATION_TAB"] == "on"
  end

  def interpretation_tab_label(topic)
    topic.interpretation_content.present? ? "질의·회신 예시" : "유권해석"
  end
end
