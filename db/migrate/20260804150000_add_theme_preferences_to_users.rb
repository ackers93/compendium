class AddThemePreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :theme_preferences, :jsonb, default: {}, null: false
  end
end
