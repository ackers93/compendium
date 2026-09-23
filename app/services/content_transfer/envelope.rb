# frozen_string_literal: true

module ContentTransfer
  class Envelope
    Invalid = Class.new(StandardError)

    attr_reader :type, :source, :exported_at, :records

    def self.build(type:, source:, records:)
      payload = {
        "format" => FORMAT,
        "version" => VERSION,
        "type" => type,
        "source" => source.to_s.presence || "compendium",
        "exported_at" => Time.current.iso8601,
        "records" => records
      }
      JSON.pretty_generate(payload)
    end

    def self.parse(json)
      text = json.to_s
      raise Invalid, "File is empty" if text.blank?

      data = JSON.parse(text)
      new(data)
    rescue JSON::ParserError => e
      raise Invalid, "File is not valid JSON (#{e.message})"
    end

    def initialize(data)
      raise Invalid, "Expected a JSON object" unless data.is_a?(Hash)

      unless data["format"] == FORMAT
        raise Invalid, "Not a Compendium export file"
      end

      unless data["version"].to_i == VERSION
        raise Invalid, "Unsupported export version #{data["version"].inspect}"
      end

      @type = data["type"].to_s
      raise Invalid, "Export type is missing" if @type.blank?

      @source = data["source"].to_s.presence || "compendium"
      @exported_at = data["exported_at"]
      @records = data["records"]
      raise Invalid, "records must be an array" unless @records.is_a?(Array)
    end
  end
end
