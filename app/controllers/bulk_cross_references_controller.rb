class BulkCrossReferencesController < ApplicationController
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

    if entries.none? { |entry| row_filled?(entry) }
      flash.now[:alert] = "Add at least one source and target verse to upload."
      @rows = default_rows
      render :new, status: :unprocessable_entity
      return
    end

    entries.each_with_index do |entry, index|
      source_reference = entry[:source_reference].to_s.strip
      target_reference = entry[:target_reference].to_s.strip
      content = entry[:content].to_s.strip

      @rows << {
        source_reference: source_reference,
        target_reference: target_reference,
        content: content,
        result: nil
      }

      next unless row_filled?(entry)

      if source_reference.blank?
        record_error(index, "Source verse is required")
        next
      end

      if target_reference.blank?
        record_error(index, "Target verse is required")
        next
      end

      source = VerseReferenceResolver.call(source_reference, allow_range: false)
      if source.error
        record_error(index, "Source: #{source.error}")
        next
      end

      target = VerseReferenceResolver.call(target_reference, allow_range: true)
      if target.error
        record_error(index, "Target: #{target.error}")
        next
      end

      result = create_cross_reference(
        source_verse: source.verse,
        target_verse: target.verse,
        target_end_verse: target.end_verse,
        content: content
      )

      if result[:error]
        record_error(index, result[:error])
      else
        success_count += 1
        @results << { index: index, success: true, reference: result[:reference] }
        @rows.last[:result] = { success: true, reference: result[:reference] }
      end
    end

    if success_count.positive? && @results.none? { |result| result[:error] }
      redirect_to new_bulk_cross_reference_path,
                  notice: "Successfully uploaded #{success_count} cross-#{'reference'.pluralize(success_count)}."
    else
      flash.now[:alert] = build_result_flash(success_count) if @results.any? { |result| result[:error] }
      render :new, status: :unprocessable_entity
    end
  end

  private

  def create_cross_reference(source_verse:, target_verse:, target_end_verse:, content:)
    if source_verse.id == target_verse.id || (target_end_verse && source_verse.id == target_end_verse.id)
      return { error: "Source and target verses must be different" }
    end

    existing_ref = CrossReference.find_by(
      "(source_verse_id = ? AND target_verse_id = ?) OR (source_verse_id = ? AND target_verse_id = ?)",
      source_verse.id, target_verse.id, target_verse.id, source_verse.id
    )

    if existing_ref
      if content.present?
        comment = existing_ref.comments.build(content: content, user: current_user)
        unless comment.save
          return { error: comment.errors.full_messages.to_sentence }
        end
      end

      return { reference: existing_ref.connection_label }
    end

    cross_reference = CrossReference.new(
      source_verse: source_verse,
      target_verse: target_verse,
      target_end_verse: target_end_verse,
      user: current_user
    )

    unless cross_reference.save
      return { error: cross_reference.errors.full_messages.to_sentence }
    end

    if content.present?
      comment = cross_reference.comments.build(content: content, user: current_user)
      unless comment.save
        return { error: comment.errors.full_messages.to_sentence }
      end
    end

    { reference: cross_reference.connection_label }
  end

  def record_error(index, message)
    @results << { index: index, error: message }
    @rows.last[:result] = { error: message }
  end

  def row_filled?(entry)
    entry[:source_reference].to_s.strip.present? ||
      entry[:target_reference].to_s.strip.present? ||
      entry[:content].to_s.strip.present?
  end

  def default_rows
    Array.new(DEFAULT_ROW_COUNT) { { source_reference: "", target_reference: "", content: "" } }
  end

  def rows_from_params
    normalize_entries(params[:entries]).map do |entry|
      {
        source_reference: entry[:source_reference].to_s,
        target_reference: entry[:target_reference].to_s,
        content: entry[:content].to_s
      }
    end
  end

  def normalize_entries(entries_param)
    return [] if entries_param.blank?

    entries = if entries_param.is_a?(ActionController::Parameters) || entries_param.is_a?(Hash)
                entries_param.values
              else
                Array(entries_param)
              end

    entries.map do |entry|
      entry = entry.permit(:source_reference, :target_reference, :content) if entry.respond_to?(:permit)
      {
        source_reference: entry[:source_reference],
        target_reference: entry[:target_reference],
        content: entry[:content]
      }
    end
  end

  def build_result_flash(success_count)
    failed_count = @results.count { |result| result[:error] }
    parts = []
    parts << "#{success_count} cross-#{'reference'.pluralize(success_count)} uploaded" if success_count.positive?
    parts << "#{failed_count} #{'row'.pluralize(failed_count)} need attention" if failed_count.positive?
    parts.join(". ") + "."
  end
end
