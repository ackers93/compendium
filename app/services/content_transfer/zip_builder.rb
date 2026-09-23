# frozen_string_literal: true

require "zlib"

module ContentTransfer
  # Uncompressed ZIP (STORE) so exports do not need an extra gem.
  class ZipBuilder
    def self.build(entries)
      new(entries).build
    end

    def initialize(entries)
      @entries = entries
    end

    def build
      locals = +"".b
      central = +"".b
      offset = 0

      @entries.each do |name, content|
        data = content.to_s.encode(Encoding::UTF_8).b
        name_b = name.to_s.encode(Encoding::UTF_8).b
        crc = Zlib.crc32(data)

        local = [
          0x04034b50, 20, 0, 0, 0, 0,
          crc, data.bytesize, data.bytesize,
          name_b.bytesize, 0
        ].pack("VvvvvvVVVvv") + name_b + data

        central << [
          0x02014b50, 20, 20, 0, 0, 0, 0,
          crc, data.bytesize, data.bytesize,
          name_b.bytesize, 0, 0, 0, 0, 0, offset
        ].pack("VvvvvvvVVVvvvvvVV") + name_b

        offset += local.bytesize
        locals << local
      end

      count = @entries.size
      eocd = [0x06054b50, 0, 0, count, count, central.bytesize, locals.bytesize, 0].pack("VvvvvVVv")
      locals << central << eocd
    end
  end
end
