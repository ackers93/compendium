class AddOnboardingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :onboarding_completed_at, :datetime
    add_column :users, :admin_onboarding_completed_at, :datetime
  end
end
