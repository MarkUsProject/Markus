# frozen_string_literal: true

module TTFunk
  class Table
    class Glyf
      # TrueType-compatible representation of a CFF glyph.
      class PathBased
        # Glyph outline.
        # @return [TTFunk::Table::Cff::Path]
        attr_reader :path

        # Glyph horizontal metrics.
        # @return [TTFunk::Table::Hmtx::HorizontalMetric]
        attr_reader :horizontal_metrics

        # Minimum X.
        # @return [Integer, Float]
        attr_reader :x_min

        # Minimum Y.
        # @return [Integer, Float]
        attr_reader :y_min

        # Maximum X.
        # @return [Integer, Float]
        attr_reader :x_max

        # Maximum Y.
        # @return [Integer, Float]
        attr_reader :y_max

        # Left side bearing.
        # @return [Integer, Float]
        attr_reader :left_side_bearing

        # Rigth side bearing.
        # @return [Integer, Float]
        attr_reader :right_side_bearing

        # @param path [TTFunk::Table::Cff::Path]
        # @param horizontal_metrics [TTFunk::Table::Hmtx::HorizontalMetric]
        def initialize(path, horizontal_metrics)
          @path = path
          @horizontal_metrics = horizontal_metrics

          @x_min = 0
          @y_min = 0
          @x_max = horizontal_metrics.advance_width
          @y_max = 0

          path.commands.each do |command|
            cmd, x, y = command
            next if cmd == :close

            @x_min = x if x < @x_min
            @x_max = x if x > @x_max
            @y_min = y if y < @y_min
            @y_max = y if y > @y_max
          end

          @left_side_bearing = horizontal_metrics.left_side_bearing
          @right_side_bearing =
            horizontal_metrics.advance_width -
            @left_side_bearing -
            (@x_max - @x_min)
        end

        # Number of contour.
        #
        # @return [Integer]
        def number_of_contours
          path.number_of_contours
        end

        # Is this glyph compound?
        #
        # @return [false]
        def compound?
          false
        end
      end
    end
  end
end
