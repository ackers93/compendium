module Admin
  class UsersController < ApplicationController
    include Authorizable
    before_action :authenticate_user!
    before_action :authorize_admin!
    before_action :set_user, only: [:edit, :update, :destroy]
    
    def index
      @users = User.order(created_at: :desc)
      
      # Filter by role if specified
      if params[:role].present? && User.roles.keys.include?(params[:role])
        @users = @users.where(role: params[:role])
      end
      
      @viewer_count = User.role_viewer.count
      @contributor_count = User.role_contributor.count
      @admin_count = User.role_admin.count
    end
    
    def edit
    end
    
    def update
      old_role = @user.role
      new_role = user_params[:role]

      if promoting_without_agreement?(old_role, new_role)
        redirect_to edit_admin_user_path(@user),
                    alert: "#{@user.email} has not accepted the Contributor Agreement yet. They must accept it before they can be promoted."
        return
      end

      if @user.update(user_params)
        # Reset admin onboarding if user was promoted to admin
        if @user.role_admin? && old_role != 'admin'
          @user.update_column(:admin_onboarding_completed_at, nil)
        end
        
        # Send email notification if role changed
        if old_role != @user.role
          RoleChangeMailer.notify_role_change(@user, old_role, @user.role, current_user.display_name).deliver_now
        end
        
        redirect_to admin_users_path, notice: "#{@user.email} was successfully updated to #{@user.role}."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete yourself."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User was successfully deleted."
      end
    end

    def reset_onboarding
      count = User.count
      User.reset_all_user_onboarding!
      redirect_to onboarding_path, notice: "Onboarding reset for #{count} #{'user'.pluralize(count)}. Everyone will see the feature tour again."
    end
    
    private
    
    def set_user
      @user = User.find(params[:id])
    end
    
    def user_params
      params.require(:user).permit(:role)
    end

    def promoting_without_agreement?(old_role, new_role)
      return false if @user.eligible_for_contributor_promotion?
      return false if new_role.blank? || new_role == old_role
      return false if new_role == 'viewer'

      old_role == 'viewer' && %w[contributor admin].include?(new_role)
    end
  end
end

