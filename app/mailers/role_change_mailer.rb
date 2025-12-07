class RoleChangeMailer < ApplicationMailer
  def notify_role_change(user, old_role, new_role, changed_by_admin)
    @user = user
    @old_role = old_role
    @new_role = new_role
    @changed_by_admin = changed_by_admin
    
    mail(
      to: user.email,
      subject: "Your Role Has Been Changed - Christadelphian Compendium"
    )
  end
end
