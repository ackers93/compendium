class CreateChiasmLimbs < ActiveRecord::Migration[8.0]
  def change
    create_table :chiasm_limbs do |t|
      t.references :chiasm, null: false, foreign_key: true
      t.integer :position, null: false
      t.integer :start_offset, null: false
      t.integer :end_offset, null: false
      t.text :note

      t.timestamps
    end

    add_index :chiasm_limbs, [:chiasm_id, :position]
  end
end
