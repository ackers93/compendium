class ContentFlagsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    @flaggable = find_flaggable
    
    if @flaggable.nil?
      redirect_back fallback_location: root_path, alert: "Content not found."
      return
    end
    
    # Check if user already flagged this content
    existing_flag = ContentFlag.find_by(
      flaggable: @flaggable,
      user: current_user,
      status: 'pending'
    )
    
    if existing_flag
      redirect_back fallback_location: root_path, alert: "You have already flagged this content."
      return
    end
    
    @flag = ContentFlag.new(content_flag_params)
    @flag.flaggable = @flaggable
    @flag.user = current_user
    
    if @flag.save
      redirect_back fallback_location: root_path, notice: "Content has been flagged for review. Thank you for helping maintain quality."
    else
      redirect_back fallback_location: root_path, alert: "Unable to flag content. Please try again."
    end
  end
  
  private
  
  def find_flaggable
    if params[:note_id]
      Note.find_by(id: params[:note_id])
    elsif params[:comment_id]
      Comment.find_by(id: params[:comment_id])
    elsif params[:cross_reference_id]
      CrossReference.find_by(id: params[:cross_reference_id])
    end
  end
  
  def content_flag_params
    params.require(:content_flag).permit(:reason)
  end
end

