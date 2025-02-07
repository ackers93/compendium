class AddBibleVerseIdToComments < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :bible_verse_id, :integer
  end
end
