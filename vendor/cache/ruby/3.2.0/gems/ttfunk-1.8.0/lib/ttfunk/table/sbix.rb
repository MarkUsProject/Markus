# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # Standard Bitmap Graphics (`sbix`) table.
    class Sbix < Table
      # Table version.
      # @return [Integer]
      attr_reader :version

      # Flags.
      # @return [Integer]
      attr_reader :flags

      # Number of bitmap strikes.
      # @return [Integer]
      attr_reader :num_strikes

      # Strikes.
      # @return [Array<Hash>]
      attr_reader :strikes

      # Bitmap Data.
      #
      # @!attribute [rw] x
      #   The horizontal (x-axis) position of the left edge of the bitmap
      #   graphic in relation to the glyph design space origin.
      # @!attribute [rw] y
      #   The vertical (y-axis) position of the bottom edge of the bitmap
      #   graphic in relation to the glyph design space origin.
      # @!attribute [rw] type
      #   Indicates the format of the embedded graphic data: one of `jpg `,
      #   `png `, `tiff`, or the special format `dupe`.
      # @!attribute [rw] data
      #   The actual embedded graphic data.
      # @!attribute [rw] ppem
      #   The PPEM size for which this strike was designed.
      # @!attribute [rw] resolution
      #   The device pixel density (in PPI) for which this strike was designed.
      BitmapData = Struct.new(:x, :y, :type, :data, :ppem, :resolution)

      # Get bitmap for glyph strike.
      #
      # @param glyph_id [Integer]
      # @param strike_index [Integer]
      # @return [BitmapData]
      def bitmap_data_for(glyph_id, strike_index)
        strike = strikes[strike_index]
        return if strike.nil?

        glyph_offset = strike[:glyph_data_offset][glyph_id]
        next_glyph_offset = strike[:glyph_data_offset][glyph_id + 1]

        if glyph_offset && next_glyph_offset
          bytes = next_glyph_offset - glyph_offset
          if bytes.positive?
            parse_from(offset + strike[:offset] + glyph_offset) {
              x, y, type = read(8, 's2A4')
              data = StringIO.new(io.read(bytes - 8))
              BitmapData.new(x, y, type, data, strike[:ppem], strike[:resolution])
            }
          end
        end
      end

      # Get all bitmaps for glyph.
      #
      # @param glyph_id [Integer]
      # @return [Array<BitmapData>]
      def all_bitmap_data_for(glyph_id)
        strikes.each_index.filter_map { |strike_index|
          bitmap_data_for(glyph_id, strike_index)
        }
      end

      private

      def parse!
        @version, @flags, @num_strikes = read(8, 'n2N')
        strike_offsets = Array.new(num_strikes) { read(4, 'N').first }

        @strikes =
          strike_offsets.map { |strike_offset|
            parse_from(offset + strike_offset) {
              ppem, resolution = read(4, 'n2')
              data_offsets =
                Array.new(file.maximum_profile.num_glyphs + 1) {
                  read(4, 'N').first
                }
              {
                ppem: ppem,
                resolution: resolution,
                offset: strike_offset,
                glyph_data_offset: data_offsets,
              }
            }
          }
      end
    end
  end
end
