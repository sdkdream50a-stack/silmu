class CreateCafeArticles < ActiveRecord::Migration[8.1]
  def change
    # PostgreSQL trigram 확장 활성화
    enable_extension 'pg_trgm'

    create_table :cafe_articles do |t|
      t.integer :article_id
      t.string :title
      t.string :author
      t.string :board
      t.datetime :written_at
      t.integer :view_count
      t.integer :comment_count
      t.integer :like_count
      t.string :url

      t.timestamps
    end

    add_index :cafe_articles, :article_id, unique: true
    add_index :cafe_articles, :board
    add_index :cafe_articles, :view_count

    # PostgreSQL 전문검색 인덱스
    execute <<-SQL
      CREATE INDEX cafe_articles_title_trgm_idx ON cafe_articles USING gin (title gin_trgm_ops);
    SQL
  end
end
