class AddOtpToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_sent_at, :datetime
    add_column :users, :otp_required_for_login, :boolean, default: true, null: false
  end
end
