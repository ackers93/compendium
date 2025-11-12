class AddUserIdToCrossReferences < ActiveRecord::Migration[8.0]
  def change
    # Add the column as nullable first
    add_reference :cross_references, :user, foreign_key: true
    
    # Update existing records to use the first user (or create one if none exists)
    reversible do |dir|
      dir.up do
        if User.any?
          first_user = User.first
          execute "UPDATE cross_references SET user_id = #{first_user.id} WHERE user_id IS NULL"
        end
      end
    end
    
    # Now make it not nullable
    change_column_null :cross_references, :user_id, false
  end
end
