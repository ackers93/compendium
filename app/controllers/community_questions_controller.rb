class CommunityQuestionsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_community_question, only: [:show, :edit, :update, :destroy]
  before_action :authorize_create!, only: [:new, :create]
  before_action -> { authorize_edit!(@community_question) }, only: [:edit, :update]
  before_action -> { authorize_delete!(@community_question) }, only: [:destroy]

  def index
    @community_questions = CommunityQuestion.includes(:user).recent
    @answer_counts = CommunityAnswer.roots
                                    .where(community_question_id: @community_questions.map(&:id))
                                    .group(:community_question_id)
                                    .count
  end

  def show
    @roots, @children_by_parent = CommunityAnswer.thread_for(@community_question)
    @community_answer = @community_question.community_answers.build
  end

  def new
    @community_question = CommunityQuestion.new
  end

  def create
    @community_question = CommunityQuestion.new(community_question_params)
    @community_question.user = current_user

    if @community_question.save
      redirect_to @community_question, notice: "Question posted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @community_question.update(community_question_params)
      redirect_to @community_question, notice: "Question updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @community_question.destroy
    redirect_to community_questions_path, notice: "Question removed."
  end

  private

  def set_community_question
    @community_question = CommunityQuestion.find(params[:id])
  end

  def community_question_params
    params.require(:community_question).permit(:title, :content)
  end
end
