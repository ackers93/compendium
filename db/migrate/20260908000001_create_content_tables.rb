class CreateContentTables < ActiveRecord::Migration[8.0]
  def change
    create_table :content_tables do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :column_count, null: false, default: 3
      t.integer :row_count, null: false, default: 3
      t.json :cells, null: false, default: []
      t.json :style, null: false, default: {}

      t.timestamps
    end

    add_index :content_tables, [:user_id, :created_at]
  end
end
