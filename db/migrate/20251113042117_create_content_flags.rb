class CreateContentFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :content_flags do |t|
      t.references :flaggable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.text :reason
      t.string :status, default: 'pending', null: false
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.text :admin_note

      t.timestamps
    end
    
    add_index :content_flags, :status
    add_index :content_flags, [:flaggable_type, :flaggable_id]
  end
end
