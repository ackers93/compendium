class BulkUploadsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :authorize_create!

  DEFAULT_ROW_COUNT = 5

  def new
    @rows = rows_from_params.presence || default_rows
    @results = @results || []
  end

  def create
    @rows = []
    @results = []
    success_count = 0

    entries = normalize_entries(params[:entries])

    if entries.none? { |entry| entry[:reference].to_s.strip.present? || entry[:content].to_s.strip.present? }
      flash.now[:alert] = "Add at least one verse and comment to upload."
      @rows = default_rows
      render :new, status: :unprocessable_entity
      return
    end

    entries.each_with_index do |entry, index|
      reference = entry[:reference].to_s.strip
      content = entry[:content].to_s.strip

      @rows << { reference: reference, content: content, result: nil }

      next if reference.blank? && content.blank?

      if reference.blank?
        @results << { index: index, error: "Verse reference is required" }
        @rows.last[:result] = { error: "Verse reference is required" }
        next
      end

      if content.blank?
        @results << { index: index, error: "Comment is required" }
        @rows.last[:result] = { error: "Comment is required" }
        next
      end

      parsed = VerseReferenceParser.parse(reference)
      unless parsed
        message = "Could not parse \"#{reference}\". Try formats like gen1:1, Gen 1:1, or Genesis 1:1-4."
        @results << { index: index, error: message }
        @rows.last[:result] = { error: message }
        next
      end

      verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.start_verse)
      unless verse
        message = "Verse not found: #{parsed.display}"
        @results << { index: index, error: message }
        @rows.last[:result] = { error: message }
        next
      end

      comment = Comment.new(user: current_user, commentable: verse, content: content)

      if parsed.end_verse
        end_verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.end_verse)
        unless end_verse
          message = "End verse not found: #{parsed.book} #{parsed.chapter}:#{parsed.end_verse}"
          @results << { index: index, error: message }
          @rows.last[:result] = { error: message }
          next
        end
        comment.end_verse = end_verse
      end

      if comment.save
        success_count += 1
        @results << { index: index, success: true, reference: comment.verse_reference }
        @rows.last[:result] = { success: true, reference: comment.verse_reference }
      else
        message = comment.errors.full_messages.to_sentence
        @results << { index: index, error: message }
        @rows.last[:result] = { error: message }
      end
    end

    if success_count.positive? && @results.none? { |result| result[:error] }
      redirect_to new_bulk_upload_path, notice: "Successfully uploaded #{success_count} #{'comment'.pluralize(success_count)}."
    else
      flash.now[:alert] = build_result_flash(success_count) if @results.any? { |result| result[:error] }
      render :new, status: :unprocessable_entity
    end
  end

  private

  def default_rows
    Array.new(DEFAULT_ROW_COUNT) { { reference: "", content: "" } }
  end

  def rows_from_params
    normalize_entries(params[:entries]).map do |entry|
      {
        reference: entry[:reference].to_s,
        content: entry[:content].to_s
      }
    end
  end

  def normalize_entries(entries_param)
    return [] if entries_param.blank?

    if entries_param.is_a?(ActionController::Parameters) || entries_param.is_a?(Hash)
      entries_param.values
    else
      Array(entries_param)
    end.map do |entry|
      entry = entry.permit(:reference, :content) if entry.respond_to?(:permit)
      {
        reference: entry[:reference],
        content: entry[:content]
      }
    end
  end

  def build_result_flash(success_count)
    failed_count = @results.count { |result| result[:error] }
    parts = []
    parts << "#{success_count} #{'comment'.pluralize(success_count)} uploaded" if success_count.positive?
    parts << "#{failed_count} #{'row'.pluralize(failed_count)} need attention" if failed_count.positive?
    parts.join(". ") + "."
  end
end
