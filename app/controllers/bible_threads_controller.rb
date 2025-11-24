class BibleThreadsController < ApplicationController
  include Authorizable
  
  before_action :authenticate_user!
  before_action :set_bible_thread, only: [:show, :edit, :update, :destroy]
  before_action :authorize_create!, only: %i[ new create ]
  before_action -> { authorize_edit!(@bible_thread) }, only: %i[ edit update ]
  before_action -> { authorize_delete!(@bible_thread) }, only: %i[ destroy ]

  def index
    @bible_threads = BibleThread.includes(:user, :bible_verses).order(created_at: :desc)
  end

  def show
    @bible_thread_entries = @bible_thread.bible_thread_entries.includes(:bible_verse).order(:position)
  end

  def new
    @bible_thread = BibleThread.new
    @bible_thread.bible_thread_entries.build
  end

  def create
    @bible_thread = BibleThread.new(bible_thread_params)
    @bible_thread.user = current_user

    if @bible_thread.save
      redirect_to @bible_thread, notice: "Bible thread was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bible_thread.update(bible_thread_params)
      redirect_to @bible_thread, notice: "Bible thread was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bible_thread.destroy
    redirect_to bible_threads_path, notice: "Bible thread was successfully deleted."
  end

  private

  def set_bible_thread
    @bible_thread = BibleThread.includes(bible_thread_entries: :bible_verse).find(params[:id])
  end

  def bible_thread_params
    params.require(:bible_thread).permit(
      :title,
      bible_thread_entries_attributes: [:id, :bible_verse_id, :position, :comment, :_destroy]
    )
  end
end

