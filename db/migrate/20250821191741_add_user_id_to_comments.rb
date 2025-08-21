class AddUserIdToComments < ActiveRecord::Migration[8.0]
  def change
    add_reference :comments, :user, null: false, foreign_key: true
  end
end