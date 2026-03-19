class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :bookmarkable_type, null: false
      t.bigint :bookmarkable_id, null: false

      t.timestamps
    end

    # 같은 리소스를 중복 북마크하지 못하도록 복합 유니크 인덱스
    add_index :bookmarks, [:user_id, :bookmarkable_type, :bookmarkable_id],
              unique: true,
              name: "index_bookmarks_on_user_and_bookmarkable"

    # 폴리모픽 조회용 인덱스
    add_index :bookmarks, [:bookmarkable_type, :bookmarkable_id],
              name: "index_bookmarks_on_bookmarkable"
  end
end
