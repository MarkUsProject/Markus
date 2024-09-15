# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # Font Header (`head`) Table.
    class Head < TTFunk::Table
      # Table version.
      # @return [Integer]
      attr_reader :version

      # Font revision.
      # @return [Integer]
      attr_reader :font_revision

      # Checksum adjustment.
      # @return [Integer]
      attr_reader :checksum_adjustment

      # Magic number.
      # @return [Integer] must be `0x5F0F3CF5`
      attr_reader :magic_number

      # Flags.
      # @return [Integer]
      attr_reader :flags

      # Units per Em.
      # @return [Integer]
      attr_reader :units_per_em

      # Font creation time.
      # @return [Integer] Long Date Time timestamp.
      attr_reader :created

      # Font modification time.
      # @return [Integer] Long Date Time timestamp.
      attr_reader :modified

      # Minimum x coordinate across all glyph bounding boxes.
      # @return [Integer]
      attr_reader :x_min

      # Minimum y coordinate across all glyph bounding boxes.
      # @return [Integer]
      attr_reader :y_min

      # Maximum x coordinate across all glyph bounding boxes.
      # @return [Integer]
      attr_reader :x_max

      # Maximum y coordinate across all glyph bounding boxes.
      # @return [Integer]
      attr_reader :y_max

      # Mac font style.
      # @return [Integer]
      attr_reader :mac_style

      # Smallest readable size in pixels.
      # @return [Integer]
      attr_reader :lowest_rec_ppem

      # Font direction hint. Deprecated, set to 2.
      # @return [Integer]
      attr_reader :font_direction_hint

      # Index to Location format.
      # @return [Integer]
      attr_reader :index_to_loc_format

      # Glyph data format.
      # @return [Integer]
      attr_reader :glyph_data_format

      class << self
        # Long date time (used in TTF headers).
        # January 1, 1904 00:00:00 UTC basis used by Long date time.
        # @see https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html
        #   TrueType Font Tables
        LONG_DATE_TIME_BASIS = Time.new(1904, 1, 1, 0, 0, 0, 0).to_i
        private_constant :LONG_DATE_TIME_BASIS

        # Encode table.
        #
        # @param head [TTFunk::Table::Head]
        # @param loca [Hash] result of encoding Index to Location (`loca`) table
        # @param mapping [Hash{Integer => Integer}] keys are new glyph IDs, values
        #   are old glyph IDs
        # @return [EncodedString]
        def encode(head, loca, mapping)
          EncodedString.new do |table|
            table <<
              [head.version, head.font_revision].pack('N2') <<
              Placeholder.new(:checksum, length: 4) <<
              [
                head.magic_number,
                head.flags, head.units_per_em,
                head.created, head.modified,
                *min_max_values_for(head, mapping),
                head.mac_style, head.lowest_rec_ppem, head.font_direction_hint,
                loca[:type] || 0, head.glyph_data_format,
              ].pack('Nn2q>2n*')
          end
        end

        # Convert Long Date Time timestamp to Time.
        # @param ldt [Float, Integer]
        # @return [Time]
        def from_long_date_time(ldt)
          Time.at(ldt + LONG_DATE_TIME_BASIS, in: 'UTC')
        end

        # Convert Time to Long Date Time timestamp
        # @param time [Time]
        # @return [Integer]
        def to_long_date_time(time)
          Integer(time) - LONG_DATE_TIME_BASIS
        end

        private

        def min_max_values_for(head, mapping)
          x_min = Min.new
          x_max = Max.new
          y_min = Min.new
          y_max = Max.new

          mapping.each_value do |old_glyph_id|
            glyph = head.file.find_glyph(old_glyph_id)
            next unless glyph

            x_min << glyph.x_min
            x_max << glyph.x_max
            y_min << glyph.y_min
            y_max << glyph.y_max
          end

          [
            x_min.value_or(0), y_min.value_or(0),
            x_max.value_or(0), y_max.value_or(0),
          ]
        end
      end

      private

      def parse!
        @version, @font_revision, @check_sum_adjustment, @magic_number,
          @flags, @units_per_em, @created, @modified = read(36, 'N4n2q>2')

        @x_min, @y_min, @x_max, @y_max = read_signed(4)

        @mac_style, @lowest_rec_ppem, @font_direction_hint,
          @index_to_loc_format, @glyph_data_format = read(10, 'n*')
      end
    end
  end
end
