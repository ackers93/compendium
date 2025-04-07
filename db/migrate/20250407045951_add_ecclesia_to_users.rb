class AddEcclesiaToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :ecclesia, :string
  end
end
