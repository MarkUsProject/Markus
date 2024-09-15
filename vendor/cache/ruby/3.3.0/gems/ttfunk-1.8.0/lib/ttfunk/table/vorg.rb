# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # Vertical Origin (`VORG`) table.
    class Vorg < Table
      # Table tag.
      TAG = 'VORG'

      # Table major version.
      # @return [Integer]
      attr_reader :major_version

      # Table minor version.
      # @return [Integer]
      attr_reader :minor_version

      # The default y coordinate of a glyph’s vertical origin.
      # @return [Integer]
      attr_reader :default_vert_origin_y

      # Number of vertical origin metrics.
      # @return [Integer]
      attr_reader :count

      # Encode table.
      #
      # @return [String]
      def self.encode(vorg)
        return unless vorg

        ''.b.tap do |table|
          table << [
            vorg.major_version, vorg.minor_version,
            vorg.default_vert_origin_y, vorg.count,
          ].pack('n*')

          vorg.origins.each_pair do |glyph_id, vert_origin_y|
            table << [glyph_id, vert_origin_y].pack('n*')
          end
        end
      end

      # Get vertical origina for glyph by ID.
      #
      # @param glyph_id [Integer]
      # @return [Integer]
      def for(glyph_id)
        @origins.fetch(glyph_id, default_vert_origin_y)
      end

      # Table tag.
      #
      # @return [String]
      def tag
        TAG
      end

      # Origins map.
      #
      # @return [Hash{Integer => Integer}]
      def origins
        @origins ||= {}
      end

      private

      def parse!
        @major_version, @minor_version = read(4, 'n*')
        @default_vert_origin_y = read_signed(1).first
        @count = read(2, 'n').first

        count.times do
          glyph_id = read(2, 'n').first
          origins[glyph_id] = read_signed(1).first
        end
      end
    end
  end
end
