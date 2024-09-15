# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # Horizontal Header (`hhea`) table.
    class Hhea < Table
      # Table version
      # @return [Integer]
      attr_reader :version

      # Typographic ascent.
      # @return [Integer]
      attr_reader :ascent

      # Typographic descent.
      # @return [Integer]
      attr_reader :descent

      # Typographic line gap.
      # @return [Integer]
      attr_reader :line_gap

      # Maximum advance width value in `hmtx` table.
      # @return [Integer]
      attr_reader :advance_width_max

      # Minimum left sidebearing value in `hmtx` table for glyphs with contours
      # (empty glyphs should be ignored).
      # @return [Integer]
      attr_reader :min_left_side_bearing

      # Minimum right sidebearing value.
      # @return [Integer]
      attr_reader :min_right_side_bearing

      # Maximum extent.
      # @return [Integer]
      attr_reader :x_max_extent

      # Caret slope rise.
      # @return [Integer]
      attr_reader :caret_slope_rise

      # @deprecated Use {caret_slope_rise} instead.
      # @!parse attr_reader :carot_slope_rise
      # @return [Integer]
      def carot_slope_rise
        @caret_slope_rise
      end

      # Caret slope run.
      # @return [Integer]
      attr_reader :caret_slope_run

      # @deprecated Use {caret_slope_run} instead.
      # @!parse attr_reader :carot_slope_run
      # @return [Integer]
      def carot_slope_run
        @caret_slope_run
      end

      # Caret offset.
      # @return [Integer]
      attr_reader :caret_offset

      # Metric data format. `0` for current format.
      # @return [Integer]
      attr_reader :metric_data_format

      # Number of hMetric entries in `hmtx` table.
      # @return [Integer]
      attr_reader :number_of_metrics

      class << self
        # Encode table.
        #
        # @param hhea [TTFunk::Table::Hhea] table to encode.
        # @param hmtx [TTFunk::Table::Hmtx]
        # @param original [TTFunk::File] original font file.
        # @param mapping [Hash{Integer => Integer}] keys are new glyph IDs, values
        #   are old glyph IDs
        # @return [String]
        def encode(hhea, hmtx, original, mapping)
          ''.b.tap do |table|
            table << [hhea.version].pack('N')
            table << [
              hhea.ascent, hhea.descent, hhea.line_gap,
              *min_max_values_for(original, mapping),
              hhea.caret_slope_rise, hhea.caret_slope_run, hhea.caret_offset,
              0, 0, 0, 0, hhea.metric_data_format, hmtx[:number_of_metrics],
            ].pack('n*')
          end
        end

        private

        def min_max_values_for(original, mapping)
          min_lsb = Min.new
          min_rsb = Min.new
          max_aw = Max.new
          max_extent = Max.new

          mapping.each_value do |old_glyph_id|
            horiz_metrics = original.horizontal_metrics.for(old_glyph_id)
            next unless horiz_metrics

            min_lsb << horiz_metrics.left_side_bearing
            max_aw << horiz_metrics.advance_width

            glyph = original.find_glyph(old_glyph_id)
            next unless glyph

            x_delta = glyph.x_max - glyph.x_min

            min_rsb << (horiz_metrics.advance_width - horiz_metrics.left_side_bearing - x_delta)

            max_extent << (horiz_metrics.left_side_bearing + x_delta)
          end

          [
            max_aw.value_or(0), min_lsb.value_or(0),
            min_rsb.value_or(0), max_extent.value_or(0),
          ]
        end
      end

      private

      def parse!
        @version = read(4, 'N').first
        @ascent, @descent, @line_gap = read_signed(3)
        @advance_width_max = read(2, 'n').first

        @min_left_side_bearing, @min_right_side_bearing, @x_max_extent,
          @caret_slope_rise, @caret_slope_run, @caret_offset,
          _reserved, _reserved, _reserved, _reserved,
          @metric_data_format = read_signed(11)

        @number_of_metrics = read(2, 'n').first
      end
    end
  end
end
