class RemoveContentFromNotes < ActiveRecord::Migration[8.0]
  def change
    remove_column :notes, :content, :text
  end
end