class CreateVerseMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :verse_mentions do |t|
      t.references :bible_verse, null: false, foreign_key: true
      t.references :mentionable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :verse_mentions,
              [:bible_verse_id, :mentionable_type, :mentionable_id],
              unique: true,
              name: "index_verse_mentions_uniqueness"
  end
end
