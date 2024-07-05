class CreateBibleVerses < ActiveRecord::Migration[6.1]
  def change
    create_table :bible_verses do |t|
      t.string :book, null: false
      t.integer :chapter, null: false
      t.integer :verse, null: false
      t.text :text, null: false

      t.timestamps
    end

    add_index :bible_verses, [:book, :chapter, :verse], unique: true
  end
end
