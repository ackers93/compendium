class AddContributorAgreementAcceptedAtToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :contributor_agreement_accepted_at, :datetime

    # Existing contributors and admins are grandfathered in
    execute <<-SQL.squish
      UPDATE users
      SET contributor_agreement_accepted_at = COALESCE(created_at, CURRENT_TIMESTAMP)
      WHERE role IN ('contributor', 'admin')
        AND contributor_agreement_accepted_at IS NULL
    SQL
  end

  def down
    remove_column :users, :contributor_agreement_accepted_at
  end
end
