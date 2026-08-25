class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show]

  def index
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .limit(100)
  end

  def show
    @notification.mark_as_read!
    redirect_to helpers.notification_path_for(@notification)
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
