# frozen_string_literal: true

module ContentTransfer
  module ContentTables
    module Exporter
      def self.call
        ContentTable.includes(:user).order(:id).map do |table|
          {
            "id" => table.id,
            "author_email" => table.user&.email,
            "title" => table.title,
            "column_count" => table.column_count,
            "row_count" => table.row_count,
            "cells" => table.cells,
            "style" => table.style
          }
        end
      end
    end

    class Importer < BaseImporter
      private

      def import_records
        records.each { |record| import_record(record) }
      end

      def import_record(record)
        source_id = record["id"]
        user, = resolve_author(record["author_email"])
        title = record["title"].to_s
        cells = record["cells"]

        existing = ContentTable.where(user: user, title: title).find do |table|
          table.cells == cells
        end
        if existing
          skipped!(source_id, existing)
          return
        end

        table = ContentTable.new(
          user: user,
          title: title,
          column_count: record["column_count"],
          row_count: record["row_count"],
          cells: cells,
          style: record["style"] || {}
        )

        if table.save
          imported!(source_id, table)
        else
          failed!(source_id, table.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
