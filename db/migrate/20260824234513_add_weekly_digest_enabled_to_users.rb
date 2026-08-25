class AddWeeklyDigestEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :weekly_digest_enabled, :boolean, default: true, null: false
  end
end
