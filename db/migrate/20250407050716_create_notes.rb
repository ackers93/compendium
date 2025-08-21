class CreateNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :notes do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.integer :user_id, null: false
      t.string :tag_list
      t.timestamps
    end

    add_index :notes, :user_id
    add_index :notes, :title
  end
end