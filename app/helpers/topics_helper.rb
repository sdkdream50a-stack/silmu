module TopicsHelper
  # 유권해석 탭 신뢰 표시 (2026-09-17 전수감사 G-38).
  # 운영 토픽 93개 해석 탭 중 원문을 확인한 공식 회신은 0건이고, 문서번호가 적힌 7건도 서로 다른 질의에 같은 번호
  # («계약제도과-2891»·«-3102» 각 2회)를 써서 번호 존재가 근거가 되지 못한다. 원문 확인 체계가 생기기 전까지 전부 예시로 표시한다.
  def interpretation_tab_label(topic)
    topic.interpretation_content.present? ? "질의·회신 예시" : "유권해석"
  end
end
