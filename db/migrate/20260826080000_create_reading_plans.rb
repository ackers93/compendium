class CreateReadingPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :reading_plans do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :reading_plans, :slug, unique: true

    create_table :reading_plan_days do |t|
      t.references :reading_plan, null: false, foreign_key: true
      t.integer :month, null: false
      t.integer :day, null: false

      t.timestamps
    end
    add_index :reading_plan_days, [:reading_plan_id, :month, :day], unique: true, name: "index_reading_plan_days_on_plan_month_day"

    create_table :reading_plan_passages do |t|
      t.references :reading_plan_day, null: false, foreign_key: true
      t.integer :slot, null: false
      t.integer :position, null: false, default: 0
      t.string :book, null: false
      t.integer :start_chapter, null: false
      t.integer :end_chapter, null: false
      t.integer :start_verse
      t.integer :end_verse

      t.timestamps
    end
    add_index :reading_plan_passages, [:reading_plan_day_id, :slot, :position], name: "index_reading_plan_passages_on_day_slot_position"
  end
end
