class AddStatusToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :status, :string, default: 'published', null: false
    add_index :notes, :status
  end
end
