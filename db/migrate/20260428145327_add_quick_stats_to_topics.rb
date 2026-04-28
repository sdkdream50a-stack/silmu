class AddQuickStatsToTopics < ActiveRecord::Migration[8.1]
  def change
    # Quick Answer 박스 옆에 노출되는 핵심 수치 카드 (label/value/note 형식)
    # GEO/AEO 권위자 검증 결과 검색 의도와 본문 형태 미스매치 해소용
    # speakable cssSelector .law-key-fact와 정합
    add_column :topics, :quick_stats, :jsonb, default: []
  end
end
