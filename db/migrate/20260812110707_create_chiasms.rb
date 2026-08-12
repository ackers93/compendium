class CreateChiasms < ActiveRecord::Migration[8.0]
  def change
    create_table :chiasms do |t|
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true
      t.references :start_verse, null: false, foreign_key: { to_table: :bible_verses }
      t.references :end_verse, null: false, foreign_key: { to_table: :bible_verses }

      t.timestamps
    end
  end
end
