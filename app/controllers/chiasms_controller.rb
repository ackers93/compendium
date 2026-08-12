class ChiasmsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_chiasm, only: [:show, :edit, :update, :destroy]
  before_action :authorize_create!, only: %i[new create]
  before_action -> { authorize_edit!(@chiasm) }, only: %i[edit update]
  before_action -> { authorize_delete!(@chiasm) }, only: %i[destroy]

  def index
    @chiasms = Chiasm.includes(:user, :start_verse, :end_verse, :chiasm_limbs)

    if params[:search].present?
      @chiasms = @chiasms.search_by_title_or_verses(params[:search])
    end

    @chiasms = @chiasms.order(created_at: :desc)
  end

  def show
    @chiasm_limbs = @chiasm.chiasm_limbs.order(:position)
  end

  def new
    @chiasm = Chiasm.new
    preload_range_from_params
  end

  def create
    @chiasm = Chiasm.new(chiasm_range_params)
    @chiasm.user = current_user

    if @chiasm.save
      redirect_to edit_chiasm_path(@chiasm), notice: "Chiasm created. Highlight the passage to add limbs."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chiasm.update(chiasm_update_params)
      redirect_to @chiasm, notice: "Chiasm was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chiasm.destroy
    redirect_to chiasms_path, notice: "Chiasm was successfully deleted."
  end

  private

  def set_chiasm
    @chiasm = Chiasm.includes(:user, :start_verse, :end_verse, :chiasm_limbs).find(params[:id])
  end

  def preload_range_from_params
    return unless params[:book].present? && params[:chapter].present? && params[:verse].present?

    start_verse = BibleVerse.find_by(
      book: params[:book],
      chapter: params[:chapter].to_i,
      verse: params[:verse].to_i
    )
    return unless start_verse

    @chiasm.start_verse = start_verse

    if params[:end_chapter].present? && params[:end_verse].present?
      end_verse = BibleVerse.find_by(
        book: params[:book],
        chapter: params[:end_chapter].to_i,
        verse: params[:end_verse].to_i
      )
      @chiasm.end_verse = end_verse if end_verse
    else
      @chiasm.end_verse = start_verse
    end
  end

  def chiasm_range_params
    params.require(:chiasm).permit(:title, :start_verse_id, :end_verse_id)
  end

  def chiasm_update_params
    params.require(:chiasm).permit(
      :title,
      chiasm_limbs_attributes: [:id, :position, :start_offset, :end_offset, :note, :_destroy]
    )
  end
end
