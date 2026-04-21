class CreateLawChangeSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :law_change_subscriptions do |t|
      t.string :email, null: false
      t.string :topic_slug, null: false
      t.string :topic_name
      t.references :user, null: true, foreign_key: true
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :law_change_subscriptions, [ :email, :topic_slug ], unique: true
    add_index :law_change_subscriptions, :topic_slug
  end
end
