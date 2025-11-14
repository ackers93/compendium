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
      
      if @user.update(user_params)
        # Reset admin onboarding if user was promoted to admin
        if @user.role_admin? && old_role != 'admin'
          @user.update_column(:admin_onboarding_completed_at, nil)
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
    
    private
    
    def set_user
      @user = User.find(params[:id])
    end
    
    def user_params
      params.require(:user).permit(:role)
    end
  end
end

