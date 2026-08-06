class AddTargetEndVerseToCrossReferences < ActiveRecord::Migration[8.0]
  def change
    add_reference :cross_references, :target_end_verse,
                  null: true,
                  foreign_key: { to_table: :bible_verses }
  end
end
