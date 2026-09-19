require "csv"

class OliveTreeImportsController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def create
    file = params[:file]

    if file.blank?
      flash.now[:alert] = "Choose an Olive Tree CSV export to import."
      render_bulk_upload_hub(active_tab: "olive_tree")
      return
    end

    unless csv_upload?(file)
      flash.now[:alert] = "Upload a .csv file exported from Olive Tree."
      render_bulk_upload_hub(active_tab: "olive_tree")
      return
    end

    result = Imports::OliveTreeNotesImporter.call(user: current_user, io_or_string: file)
    @import_result = result

    if result.imported_count.positive? && result.failed_count.zero?
      redirect_to bulk_upload_hub_path(tab: "olive_tree"),
                  notice: import_notice(result)
    else
      flash.now[:alert] = import_alert(result)
      render_bulk_upload_hub(active_tab: "olive_tree")
    end
  rescue CSV::MalformedCSVError
    flash.now[:alert] = "That file could not be read as a CSV. Re-download the Olive Tree export and try again."
    render_bulk_upload_hub(active_tab: "olive_tree")
  end

  private

  def csv_upload?(file)
    filename = file.original_filename.to_s.downcase
    filename.end_with?(".csv") || file.content_type.to_s.include?("csv")
  end

  def import_notice(result)
    parts = ["Imported #{result.imported_count} #{'note'.pluralize(result.imported_count)}"]
    skipped_total = result.skipped.values.sum
    parts << "skipped #{skipped_total} #{'row'.pluralize(skipped_total)}" if skipped_total.positive?
    parts.join("; ") + "."
  end

  def import_alert(result)
    parts = []
    parts << "#{result.imported_count} #{'note'.pluralize(result.imported_count)} imported" if result.imported_count.positive?
    parts << "#{result.failed_count} #{'row'.pluralize(result.failed_count)} failed" if result.failed_count.positive?
    skipped_total = result.skipped.values.sum
    parts << "#{skipped_total} #{'row'.pluralize(skipped_total)} skipped" if skipped_total.positive?
    return "No notes were imported." if parts.empty?

    parts.join(". ") + "."
  end
end
