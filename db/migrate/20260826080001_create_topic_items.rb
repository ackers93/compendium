class CreateTopicItems < ActiveRecord::Migration[8.0]
  def change
    create_table :topic_items do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :itemable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :topic_items,
              [:topic_id, :itemable_type, :itemable_id, :user_id],
              unique: true,
              name: "index_topic_items_on_topic_itemable_user"
  end
end
