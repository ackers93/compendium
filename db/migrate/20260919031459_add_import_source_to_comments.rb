class AddImportSourceToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :import_source, :string
    add_index :comments, [:user_id, :import_source, :commentable_type, :commentable_id],
              name: "index_comments_on_user_import_source_and_commentable"
  end
end
