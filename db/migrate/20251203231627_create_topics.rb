class CreateTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.string :name

      t.timestamps
    end
    add_index :topics, :name, unique: true
  end
end
