class CrossReferencesController < ApplicationController
  include Authorizable
  
  before_action :authenticate_user!
  before_action :set_source_verse, only: [:new, :create]
  before_action :set_cross_reference, only: [:destroy]
  before_action :authorize_create!, only: %i[ new create ]
  before_action -> { authorize_delete!(@cross_reference) }, only: %i[ destroy ]

  def new
    # This action renders the modal form
  end

  def create
    target_verse = BibleVerse.find_by(book: params[:book], chapter: params[:chapter], verse: params[:verse])
    
    if target_verse.nil?
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("cross-reference-form", 
            partial: "cross_references/form", locals: { 
              error: "Target verse not found",
              book: @book,
              chapter: @chapter,
              verse: @verse
            }
          )
        }
        format.html { redirect_to bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), alert: "Target verse not found" }
      end
      return
    end
    
    if @source_verse.id == target_verse.id
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("cross-reference-form", 
            partial: "cross_references/form", locals: { 
              error: "Cannot cross-reference a verse to itself",
              book: @book,
              chapter: @chapter,
              verse: @verse
            }
          )
        }
        format.html { redirect_to bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), alert: "Cannot cross-reference a verse to itself" }
      end
      return
    end
    
    # Check if cross-reference already exists (in either direction)
    existing_ref = CrossReference.find_by(
      '(source_verse_id = ? AND target_verse_id = ?) OR (source_verse_id = ? AND target_verse_id = ?)',
      @source_verse.id, target_verse.id, target_verse.id, @source_verse.id
    )
    
    if existing_ref
      # If it exists, add the comment to the existing cross-reference
      @cross_reference = existing_ref
      @comment = @cross_reference.comments.build(comment_params)
      @comment.user = current_user
      
      if @comment.save
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: [
              turbo_stream.replace("cross-references", partial: "cross_references/cross_references_list", 
                locals: { cross_references: @source_verse.ordered_cross_references, verse: @source_verse }),
              turbo_stream.update("modal", "")
            ]
          }
          format.html { redirect_to bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), notice: "Comment added to existing cross-reference" }
        end
      else
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: turbo_stream.replace("cross-reference-form-container", 
              partial: "cross_references/form", locals: { 
                comment: @comment, 
                error: @comment.errors.full_messages.join(", "),
                book: @book,
                chapter: @chapter,
                verse: @verse
              }
            )
          }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    else
      # Create new cross-reference
      @cross_reference = CrossReference.new(
        source_verse: @source_verse,
        target_verse: target_verse,
        user: current_user
      )
      
      if @cross_reference.save
        # If comment content was provided, create a comment
        if params[:comment] && params[:comment][:content].present?
          @comment = @cross_reference.comments.build(comment_params)
          @comment.user = current_user
          @comment.save
        end
        
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: [
              turbo_stream.replace("cross-references", partial: "cross_references/cross_references_list", 
                locals: { cross_references: @source_verse.ordered_cross_references, verse: @source_verse }),
              turbo_stream.update("modal", "")
            ]
          }
          format.html { redirect_to bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), notice: "Cross-reference created successfully" }
        end
      else
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: turbo_stream.replace("cross-reference-form", 
              partial: "cross_references/form", locals: { 
                error: @cross_reference.errors.full_messages.join(", "),
                book: @book,
                chapter: @chapter,
                verse: @verse
              }
            )
          }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    # This action is now for deleting comments, not cross-references
    # We'll handle this differently
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Invalid action" }
      format.json { render json: { error: "Invalid action" }, status: :unprocessable_entity }
    end
  end

  private

  def set_source_verse
    @source_verse = BibleVerse.find_by(
      book: params[:source_book], 
      chapter: params[:source_chapter], 
      verse: params[:source_verse]
    )
    
    # Set the instance variables needed for the form
    @book = params[:source_book]
    @chapter = params[:source_chapter]
    @verse = params[:source_verse]
    
    unless @source_verse
      # Don't try to render here - just set a flash message and let the action handle it
      flash[:alert] = "Source verse not found"
      redirect_to root_path
      return
    end
  end

  def set_cross_reference
    @cross_reference = CrossReference.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
