class AddEndVerseToComments < ActiveRecord::Migration[8.0]
  def change
    add_reference :comments, :end_verse,
                  null: true,
                  foreign_key: { to_table: :bible_verses }
  end
end
