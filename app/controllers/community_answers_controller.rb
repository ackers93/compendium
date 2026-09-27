class CommunityAnswersController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_community_question
  before_action :set_community_answer, only: [:edit, :update, :destroy]
  before_action :authorize_create!, only: [:new, :create]
  before_action -> { authorize_edit!(@community_answer) }, only: [:edit, :update]
  before_action -> { authorize_delete!(@community_answer) }, only: [:destroy]
  before_action :ensure_frame_response, only: [:new, :edit]

  def new
    @community_answer = @community_question.community_answers.build
    assign_parent(@community_answer, params[:parent_id])
  end

  def create
    @community_answer = @community_question.community_answers.build(answer_attributes)
    @community_answer.user = current_user
    assign_parent(@community_answer, community_answer_params[:parent_id])

    if @community_answer.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: refresh_streams }
        format.html { redirect_to @community_question, notice: @community_answer.reply? ? "Reply posted." : "Answer posted." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            form_target,
            partial: "community_answers/form",
            locals: { community_answer: @community_answer, community_question: @community_question }
          ), status: :unprocessable_entity
        end
        format.html do
          if @community_answer.reply?
            render :new, status: :unprocessable_entity
          else
            @roots, @children_by_parent = CommunityAnswer.thread_for(@community_question)
            render "community_questions/show", status: :unprocessable_entity
          end
        end
      end
    end
  end

  def edit
  end

  def update
    if @community_answer.update(answer_attributes)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              helpers.dom_id(@community_answer),
              partial: "community_answers/answer",
              locals: answer_locals(@community_answer)
            ),
            turbo_stream.update("modal", "")
          ]
        end
        format.html { redirect_to @community_question, notice: "Answer updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @community_answer.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: refresh_streams }
      format.html { redirect_to @community_question, notice: "Answer removed." }
    end
  end

  private

  def set_community_question
    @community_question = CommunityQuestion.find(params[:community_question_id])
  end

  def set_community_answer
    @community_answer = @community_question.community_answers.find(params[:id])
  end

  def community_answer_params
    params.require(:community_answer).permit(:content, :parent_id)
  end

  def answer_attributes
    community_answer_params.except(:parent_id)
  end

  def assign_parent(answer, parent_id)
    return if parent_id.blank?

    answer.parent = CommunityAnswer.find_by(id: parent_id)
  end

  def refresh_streams
    roots, children_by_parent = CommunityAnswer.thread_for(@community_question)
    [
      turbo_stream.replace(
        "community-answers",
        partial: "community_answers/list",
        locals: {
          roots: roots,
          children_by_parent: children_by_parent,
          community_question: @community_question
        }
      ),
      turbo_stream.replace(
        "community-answer-form",
        partial: "community_answers/form",
        locals: {
          community_answer: @community_question.community_answers.build,
          community_question: @community_question
        }
      ),
      turbo_stream.update("modal", "")
    ]
  end

  def form_target
    @community_answer.reply? ? "modal" : "community-answer-form"
  end

  def answer_locals(answer)
    _roots, children_by_parent = CommunityAnswer.thread_for(@community_question)
    {
      community_answer: answer,
      community_question: @community_question,
      children_by_parent: children_by_parent,
      depth: answer.depth
    }
  end

  def ensure_frame_response
    return unless Rails.env.development?
    return if params[:direct_edit] || request.referer&.include?("admin")

    redirect_to @community_question unless turbo_frame_request?
  end
end
