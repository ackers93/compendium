module Admin
  class ContentTransfersController < ApplicationController
    include Authorizable

    before_action :authenticate_user!
    before_action :authorize_admin!

    def show
      @types = ContentTransfer.types
    end

    def export
      type_key = params[:type].to_s
      source = export_source

      if type_key == "all"
        send_data ContentTransfer.export_zip(source: source),
                  filename: "compendium-all-#{Date.current}.zip",
                  type: "application/zip",
                  disposition: "attachment"
        return
      end

      type = ContentTransfer.find_type(type_key)
      unless type
        redirect_to admin_content_transfer_path, alert: "Unknown export type."
        return
      end

      send_data ContentTransfer.export(type.key, source: source),
                filename: "compendium-#{type.key}-#{Date.current}.json",
                type: "application/json; charset=utf-8",
                disposition: "attachment"
    end

    def import
      type_key = params[:type].to_s
      file = params[:file]

      unless ContentTransfer.find_type(type_key)
        redirect_to admin_content_transfer_path, alert: "Unknown import type."
        return
      end

      if file.blank?
        redirect_to admin_content_transfer_path, alert: "Choose a JSON export file to import."
        return
      end

      json = file.respond_to?(:read) ? file.read : file.to_s
      result = ContentTransfer.import(json, type: type_key, admin: current_user)
      redirect_to admin_content_transfer_path, **flash_for(result)
    rescue ContentTransfer::Envelope::Invalid => e
      redirect_to admin_content_transfer_path, alert: e.message
    end

    private

    def export_source
      request.host.to_s.presence || "compendium"
    end

    def flash_for(result)
      details = Array(result.errors).first(8).map do |row|
        "Record #{row[:id]}: #{row[:error]}"
      end
      extra = Array(result.errors).size > 8 ? " (and #{result.errors.size - 8} more)" : ""

      if result.failed_count.to_i.positive?
        { alert: [result.summary, details.join(" "), extra.presence].compact.join(" ").strip }
      else
        { notice: result.summary }
      end
    end
  end
end
