class AddHowtoStepsToTopics < ActiveRecord::Migration[8.1]
  # GEO/AEO 2026 권고 — HowTo Schema (Google AI Overviews 인용률 +22%)
  # 절차형 토픽(견적서 수집, 사유서 작성, 입찰공고 등)에 단계별 step JSON 저장.
  # 형식: [{ "name": "1단계 제목", "text": "상세 설명", "url": "https://silmu.kr/..." }, ...]
  def change
    add_column :topics, :howto_steps, :jsonb, default: []
  end
end
