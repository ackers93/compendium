class CreateCrossReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :cross_references do |t|
      t.references :source_verse, null: false, foreign_key: { to_table: :bible_verses }
      t.references :target_verse, null: false, foreign_key: { to_table: :bible_verses }

      t.timestamps
    end
    
    add_index :cross_references, [:source_verse_id, :target_verse_id], unique: true, name: 'index_cross_references_on_source_and_target'
  end
end
