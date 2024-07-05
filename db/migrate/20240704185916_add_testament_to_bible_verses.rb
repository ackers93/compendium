class AddTestamentToBibleVerses < ActiveRecord::Migration[7.0]
  def change
    add_column :bible_verses, :testament, :string
  end
end
