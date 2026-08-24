module BulkUploadHubRendering
  extend ActiveSupport::Concern

  DEFAULT_ROW_COUNT = 5
  TABS = %w[comments cross_references topics threads].freeze

  private

  def render_bulk_upload_hub(active_tab:, status: :unprocessable_entity)
    assign_bulk_hub_defaults(active_tab: active_tab)
    render "bulk_upload_hub/show", status: status
  end

  def assign_bulk_hub_defaults(active_tab:)
    @tab = active_tab
    @comment_rows = default_comment_rows if @comment_rows.nil?
    @xref_rows = default_xref_rows if @xref_rows.nil?
    @topic_title = "" if @topic_title.nil?
    @topic_verse_refs = "" if @topic_verse_refs.nil?
    @topic_errors = [] if @topic_errors.nil?
    @thread_title = "" if @thread_title.nil?
    @thread_verse_refs = "" if @thread_verse_refs.nil?
    @thread_errors = [] if @thread_errors.nil?
  end

  def default_comment_rows
    Array.new(DEFAULT_ROW_COUNT) { { reference: "", content: "" } }
  end

  def default_xref_rows
    Array.new(DEFAULT_ROW_COUNT) { { source_reference: "", target_reference: "", content: "" } }
  end
end
