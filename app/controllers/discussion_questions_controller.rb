class DiscussionQuestionsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_discussion_question, only: [:edit, :update, :destroy]
  before_action :authorize_create!, only: [:create]
  before_action -> { authorize_edit!(@discussion_question) }, only: [:edit, :update]
  before_action -> { authorize_delete!(@discussion_question) }, only: [:destroy]
  before_action :ensure_frame_response, only: [:edit]

  def index
    @discussion_questions = DiscussionQuestion.includes(:user, :questionable).recent
  end

  def create
    @questionable = find_questionable
    unless @questionable
      redirect_back fallback_location: discussion_questions_path, alert: "Could not find that verse or topic."
      return
    end

    @discussion_question = @questionable.discussion_questions.build(discussion_question_params)
    @discussion_question.user = current_user

    if @discussion_question.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "discussion-questions-list",
              partial: "discussion_questions/list",
              locals: { discussion_questions: @questionable.discussion_questions.includes(:user) }
            ),
            turbo_stream.replace(
              "discussion-question-form",
              partial: "discussion_questions/form",
              locals: {
                discussion_question: @questionable.discussion_questions.build,
                questionable: @questionable
              }
            )
          ]
        end
        format.html do
          redirect_to helpers.discussion_question_parent_path(@discussion_question),
                      notice: "Discussion question added."
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "discussion-question-form",
            partial: "discussion_questions/form",
            locals: { discussion_question: @discussion_question, questionable: @questionable }
          ), status: :unprocessable_entity
        end
        format.html { render_create_failure }
      end
    end
  end

  def edit
  end

  def update
    if @discussion_question.update(discussion_question_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              helpers.dom_id(@discussion_question),
              partial: "discussion_questions/question",
              locals: { discussion_question: @discussion_question }
            ),
            turbo_stream.update("modal", "")
          ]
        end
        format.html do
          redirect_to helpers.discussion_question_parent_path(@discussion_question),
                      notice: "Discussion question updated."
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    questionable = @discussion_question.questionable
    @discussion_question.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "discussion-questions-list",
          partial: "discussion_questions/list",
          locals: { discussion_questions: questionable.discussion_questions.includes(:user) }
        )
      end
      format.html do
        redirect_to helpers.questionable_path(questionable), notice: "Discussion question removed."
      end
    end
  end

  private

  def set_discussion_question
    @discussion_question = DiscussionQuestion.find(params[:id])
  end

  def find_questionable
    if params[:topic_id]
      Topic.find_by(id: params[:topic_id])
    elsif params[:book].present? && params[:chapter].present? && params[:verse].present?
      BibleVerse.find_by(book: params[:book], chapter: params[:chapter].to_i, verse: params[:verse].to_i)
    end
  end

  def discussion_question_params
    params.require(:discussion_question).permit(:body)
  end

  def ensure_frame_response
    return unless Rails.env.development?
    return if params[:direct_edit] || request.referer&.include?("admin")

    redirect_to root_path unless turbo_frame_request?
  end

  def render_create_failure
    if @questionable.is_a?(BibleVerse)
      redirect_to bible_verse_show_path(
        book: @questionable.book,
        chapter: @questionable.chapter,
        verse: @questionable.verse
      ), alert: @discussion_question.errors.full_messages.to_sentence
    elsif @questionable.is_a?(Topic)
      redirect_to topic_path(@questionable), alert: @discussion_question.errors.full_messages.to_sentence
    else
      redirect_to discussion_questions_path, alert: @discussion_question.errors.full_messages.to_sentence
    end
  end
end
