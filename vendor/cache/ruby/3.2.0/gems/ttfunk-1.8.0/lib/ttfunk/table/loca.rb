# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # Index to Location table.
    class Loca < Table
      # Glyph ofsets
      # @return [Array<Integer>]
      attr_reader :offsets

      # Encode table.
      #
      # @param offsets [Array<Integer>] an array of offsets, with each index
      #   corresponding to the glyph id with that index.
      # @return [Hash] result hash:
      #   * `:type` - the type of offset (to be encoded in the 'head' table):
      #     * `0` - short offsets
      #     * `1` - long offsets
      #   * `:table` - encoded bytes
      def self.encode(offsets)
        long_offsets =
          offsets.any? { |offset|
            short_offset = offset / 2
            short_offset * 2 != offset || short_offset > 0xffff
          }

        if long_offsets
          { type: 1, table: offsets.pack('N*') }
        else
          { type: 0, table: offsets.map { |o| o / 2 }.pack('n*') }
        end
      end

      # Glyph offset by ID.
      #
      # @param glyph_id [Integer]
      # @return [Integer] - offset of the glyph in the `glyf` table
      def index_of(glyph_id)
        @offsets[glyph_id]
      end

      # Size of encoded glyph.
      #
      # @param glyph_id [Integer]
      # @return [Integer]
      def size_of(glyph_id)
        @offsets[glyph_id + 1] - @offsets[glyph_id]
      end

      private

      def parse!
        type = file.header.index_to_loc_format.zero? ? 'n' : 'N'
        @offsets = read(length, "#{type}*")

        if file.header.index_to_loc_format.zero?
          @offsets.map! { |v| v * 2 }
        end
      end
    end
  end
end
