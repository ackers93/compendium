class CreateBibleThreadEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_thread_entries do |t|
      t.references :bible_thread, null: false, foreign_key: true
      t.references :bible_verse, null: false, foreign_key: true
      t.integer :position
      t.text :comment

      t.timestamps
    end
    
    add_index :bible_thread_entries, [:bible_thread_id, :position]
  end
end
