class NotesController < ApplicationController
  include Authorizable
  
  before_action :authenticate_user!
  before_action :set_note, only: %i[ show edit update destroy publish unpublish ]
  before_action :authorize_create!, only: %i[ new create ]
  before_action -> { authorize_edit!(@note) }, only: %i[ edit update publish unpublish ]
  before_action -> { authorize_delete!(@note) }, only: %i[ destroy ]

  def index
    @notes = Note.published.order(created_at: :desc)
  end
  
  def drafts
    @notes = current_user.notes.draft.order(updated_at: :desc)
    render :index
  end

  def show
    # Prevent users from viewing other people's drafts
    if @note.draft? && @note.user != current_user
      redirect_to notes_path, alert: "You don't have permission to view this draft."
      return
    end
    
    @commentable = @note
    @comment = @commentable.comments.build
    @comments = Comment.where(commentable: @note).includes(:user, :rich_text_content).order(created_at: :desc)
  end

  def new
    @note = Note.new
  end
  
  def edit
  end
  
  def create
    @note = Note.new(note_params)
    @note.user = current_user

    respond_to do |format|
      if @note.save
        notice_message = @note.draft? ? "Draft was successfully saved." : "Note was successfully published."
        redirect_path = @note.draft? ? drafts_notes_path : notes_path
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("modal", ""),  # Close the modal
            turbo_stream.prepend("notes-table-body", partial: "notes/note_row", locals: { note: @note })  # Add to table body
          ]
        }
        format.html { redirect_to redirect_path, notice: notice_message }
        format.json { render json: { id: @note.id, title: @note.title }, status: :created, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "notes/new", locals: { note: @note })
        }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @note.update(note_params)
        notice_message = if @note.draft? && @note.status_previously_was == 'published'
          "Note was converted to draft."
        elsif @note.draft?
          "Draft was successfully updated."
        elsif @note.status_previously_was == 'draft'
          "Note was successfully published."
        else
          "Note was successfully updated."
        end
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("modal", ""),  # Close the modal
            turbo_stream.replace("note-content", partial: "notes/note_content", locals: { note: @note })  # Update the note content
          ]
        }
        format.html { redirect_to @note, notice: notice_message }
        format.json { render json: { id: @note.id, title: @note.title }, status: :ok, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "notes/edit", locals: { note: @note })
        }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @note.destroy

    respond_to do |format|
      format.html { redirect_to notes_url, notice: "Note was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  def publish
    respond_to do |format|
      if @note.publish!
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.remove(dom_id(@note)),  # Remove from drafts list
          ]
        }
        format.html { redirect_to @note, notice: "Note was successfully published." }
        format.json { render json: { id: @note.id }, status: :ok }
      else
        format.html { redirect_to @note, alert: "Failed to publish note." }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def unpublish
    respond_to do |format|
      if @note.unpublish!
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("note-content", partial: "notes/note_content", locals: { note: @note })
          ]
        }
        format.html { redirect_to @note, notice: "Note was converted to draft." }
        format.json { render json: { id: @note.id }, status: :ok }
      else
        format.html { redirect_to @note, alert: "Failed to convert note to draft." }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def list
    @notes = if params[:query].present?
               Note.published
                   .joins(:rich_text_content)
                   .joins("LEFT JOIN taggings ON taggings.taggable_id = notes.id AND taggings.taggable_type = 'Note'")
                   .joins("LEFT JOIN tags ON tags.id = taggings.tag_id")
                   .joins("LEFT JOIN comments ON comments.commentable_id = notes.id AND comments.commentable_type = 'Note'")
                   .joins("LEFT JOIN action_text_rich_texts comment_content ON comment_content.record_id = comments.id AND comment_content.record_type = 'Comment' AND comment_content.name = 'content'")
                   .where("LOWER(notes.title) LIKE LOWER(?) OR LOWER(action_text_rich_texts.body) LIKE LOWER(?) OR LOWER(tags.name) LIKE LOWER(?) OR LOWER(comment_content.body) LIKE LOWER(?)", 
                          "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
                   .distinct
                   .order(created_at: :desc)
             else
               Note.published.order(created_at: :desc)
             end
    
    render "index"
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :content, :tag_list, :status)
  end
end