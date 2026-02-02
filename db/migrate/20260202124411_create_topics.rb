class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :name, null: false                    # 주제명 (예: 수의계약)
      t.string :slug, null: false                    # URL용 (예: private-contract)
      t.string :category                             # 카테고리 (계약, 예산, 급여 등)
      t.text :keywords                               # 검색 키워드 (JSON 배열)
      t.text :summary                                # 요약 설명

      # 법령 3단
      t.text :law_content                            # 법률 내용
      t.text :decree_content                         # 시행령 내용
      t.text :rule_content                           # 시행규칙 내용

      # 추가 정보
      t.text :regulation_content                     # 행정안전부 예규/지침
      t.text :interpretation_content                 # 유권해석
      t.text :audit_cases                            # 감사사례
      t.text :qa_content                             # 행안부 질의답변
      t.text :practical_tips                         # 실무 주의사항

      # 시각자료
      t.string :infographic_url                      # 인포그래픽 URL
      t.string :flowchart_url                        # 순서도 URL
      t.string :video_url                            # 동영상 URL

      t.integer :view_count, default: 0
      t.boolean :published, default: false           # 공개 여부

      t.timestamps
    end

    add_index :topics, :slug, unique: true
    add_index :topics, :category
    add_index :topics, :published
  end
end
