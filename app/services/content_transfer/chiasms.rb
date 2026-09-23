# frozen_string_literal: true

module ContentTransfer
  module Chiasms
    module Exporter
      def self.call
        Chiasm.includes(:user, :start_verse, :end_verse, :chiasm_limbs).order(:id).map do |chiasm|
          {
            "id" => chiasm.id,
            "author_email" => chiasm.user&.email,
            "title" => chiasm.title,
            "start_reference" => chiasm.start_verse&.reference,
            "end_reference" => chiasm.end_verse&.reference,
            "limbs" => chiasm.chiasm_limbs.sort_by { |limb| limb.position.to_i }.map do |limb|
              {
                "id" => limb.id,
                "position" => limb.position,
                "start_offset" => limb.start_offset,
                "end_offset" => limb.end_offset,
                "note" => limb.note
              }
            end
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

        start_verse, start_error = find_verse(record["start_reference"])
        return failed!(source_id, "Start: #{start_error}") if start_error

        end_verse, end_error = find_verse(record["end_reference"])
        return failed!(source_id, "End: #{end_error}") if end_error

        existing = Chiasm.find_by(
          user: user,
          title: title,
          start_verse: start_verse,
          end_verse: end_verse
        )
        if existing
          skipped!(source_id, existing)
          return
        end

        chiasm = Chiasm.new(
          user: user,
          title: title,
          start_verse: start_verse,
          end_verse: end_verse
        )
        Array(record["limbs"]).each do |limb_record|
          chiasm.chiasm_limbs.build(
            position: limb_record["position"],
            start_offset: limb_record["start_offset"],
            end_offset: limb_record["end_offset"],
            note: limb_record["note"]
          )
        end

        if chiasm.save
          imported!(source_id, chiasm)
          record["limbs"].to_a.zip(chiasm.chiasm_limbs.sort_by { |limb| limb.position.to_i }).each do |limb_record, limb|
            remember("ChiasmLimb", limb_record["id"], limb.id) if limb_record && limb
          end
        else
          failed!(source_id, chiasm.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
