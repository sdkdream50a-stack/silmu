module TopicsHelper
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
