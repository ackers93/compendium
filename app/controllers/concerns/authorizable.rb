module Authorizable
  extend ActiveSupport::Concern
  
  included do
    rescue_from NotAuthorized, with: :user_not_authorized
  end
  
  class NotAuthorized < StandardError; end
  
  def authorize_create!
    unless current_user&.can_create?
      raise NotAuthorized, "You must be a contributor or admin to create content"
    end
  end
  
  def authorize_edit!(resource)
    unless current_user&.can_edit?(resource)
      raise NotAuthorized, "You are not authorized to edit this content"
    end
  end
  
  def authorize_delete!(resource)
    unless current_user&.can_delete?(resource)
      raise NotAuthorized, "You are not authorized to delete this content"
    end
  end
  
  def authorize_admin!
    unless current_user&.can_manage_users?
      raise NotAuthorized, "You must be an admin to access this page"
    end
  end
  
  private
  
  def user_not_authorized(exception)
    flash[:alert] = exception.message
    redirect_to(request.referrer || root_path)
  end
end

