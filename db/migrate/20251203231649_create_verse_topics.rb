class CreateVerseTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :verse_topics do |t|
      t.references :bible_verse, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :verse_topics, [:bible_verse_id, :topic_id], unique: true
  end
end
