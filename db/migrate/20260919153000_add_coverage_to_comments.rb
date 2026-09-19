class AddCoverageToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :coverage, :string, null: false, default: "verse"
  end
end
