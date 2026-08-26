class TopicAttachmentsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_topic
  before_action :authorize_create!, only: %i[create]
  before_action :set_topic_attachment, only: %i[destroy]

  def create
    @topic_attachment = @topic.topic_attachments.build(user: current_user)
    @topic_attachment.file.attach(topic_attachment_params[:file]) if topic_attachment_params[:file].present?

    if @topic_attachment.save
      respond_to do |format|
        format.turbo_stream do
          load_attachments
          render turbo_stream: turbo_stream.replace(
            "topic-attachments",
            partial: "topic_attachments/section",
            locals: { topic: @topic, topic_attachments: @topic_attachments, errors: [] }
          )
        end
        format.html { redirect_to topic_path(@topic), notice: "Attachment uploaded." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          load_attachments
          render turbo_stream: turbo_stream.replace(
            "topic-attachments",
            partial: "topic_attachments/section",
            locals: {
              topic: @topic,
              topic_attachments: @topic_attachments,
              errors: @topic_attachment.errors.full_messages
            }
          ), status: :unprocessable_entity
        end
        format.html do
          load_attachments
          flash.now[:alert] = @topic_attachment.errors.full_messages.to_sentence
          redirect_to topic_path(@topic), alert: @topic_attachment.errors.full_messages.to_sentence
        end
      end
    end
  end

  def destroy
    authorize_delete!(@topic_attachment)
    @topic_attachment.destroy

    respond_to do |format|
      format.turbo_stream do
        load_attachments
        render turbo_stream: turbo_stream.replace(
          "topic-attachments",
          partial: "topic_attachments/section",
          locals: { topic: @topic, topic_attachments: @topic_attachments, errors: [] }
        )
      end
      format.html { redirect_to topic_path(@topic), notice: "Attachment removed." }
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def set_topic_attachment
    @topic_attachment = @topic.topic_attachments.find(params[:id])
  end

  def load_attachments
    @topic_attachments = @topic.topic_attachments.includes(:user).with_attached_file.order(created_at: :desc)
  end

  def topic_attachment_params
    params.require(:topic_attachment).permit(:file)
  end
end
