class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: %i[ show edit update destroy ]
  before_action :ensure_frame_response, only: [:new, :edit]


  def index
    puts "notes#index"
    @notes = Note.all
  end

  def show
    puts "notes#show"
    # @note = Note.where(id: params[:note_id])
    @comments = Comment.where(note_id: @note).all
  end

  def new
    puts "notes#new"
    @note = Note.new
  end

  def edit
    puts "notes#edit"
  end
  
  def create
    puts "notes#create"
    @note = Note.new(note_params)
    respond_to do |format|
      if @note.save
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('notes', partial: 'notes/note', locals: {note: @note}) }
        format.html { redirect_to note_url(@note), notice: "Note was successfully created." }
        format.json { render :show, status: :created, location: @note }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    puts "notes#update"
    respond_to do |format|
      if @note.update(note_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@note, partial: "notes/note", locals: {note: @note}) }
        format.html { redirect_to note_url(@note), notice: "Note was successfully updated." }
        format.json { render :show, status: :ok, location: @note }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    puts "notes#destroy"
    @note.destroy

    respond_to do |format|
      format.html { redirect_to notes_url, notice: "Note was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  def list
    @notes = Note.where('title ilike ?', "%#{params[:title]}%") if params[:title].present?
    render("index", locals: { notes: @notes })
  end


    private
    # Use callbacks to share common setup or constraints between actions.
    def set_note
      @note = Note.find(params[:id])
    end

    def ensure_frame_response
      return unless Rails.env.development?
      redirect_to root_path unless turbo_frame_request?
    end

    # Only allow a list of trusted parameters through.
    def note_params
      params.require(:note).permit(:title, :content, :user_id, :tag_list)
    end
end