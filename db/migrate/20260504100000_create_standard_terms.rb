class CreateStandardTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :standard_terms do |t|
      t.string :term_korean, null: false
      t.string :term_english
      t.string :domain_classification
      t.string :data_type
      t.integer :max_length
      t.string :agency_name
      t.jsonb :synonyms, default: [], null: false
      t.string :revision_round
      t.text :description

      t.timestamps
    end

    add_index :standard_terms, :term_korean, unique: true
    add_index :standard_terms, :synonyms, using: :gin
  end
end
