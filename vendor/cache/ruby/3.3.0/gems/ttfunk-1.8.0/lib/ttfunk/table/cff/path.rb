# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # Path. Mostly used for CFF glyph outlines.
      class Path
        # Close path command.
        CLOSE_PATH_CMD = [:close].freeze

        # Commands in this path.
        # @return [Array]
        attr_reader :commands

        # Number of contours in this path.
        # @return [Integer]
        attr_reader :number_of_contours

        def initialize
          @commands = []
          @number_of_contours = 0
        end

        # Move implicit cursor to coordinates.
        #
        # @param x [Integer, Float]
        # @param y [Integer, Float]
        # @return [void]
        def move_to(x, y)
          @commands << [:move, x, y]
        end

        # Add a line to coordinates.
        #
        # @param x [Integer, Float]
        # @param y [Integer, Float]
        # @return [void]
        def line_to(x, y)
          @commands << [:line, x, y]
        end

        # Add a Bézier curve. Current position is the first control point, (`x1`,
        # `y1`) is the second, (`x2`, `y2`) is the third, and (`x`, `y`) is the
        # last control point.
        #
        # @param x1 [Integer, Float]
        # @param y1 [Integer, Float]
        # @param x2 [Integer, Float]
        # @param y2 [Integer, Float]
        # @param x [Integer, Float]
        # @param y [Integer, Float]
        # @return [void]
        def curve_to(x1, y1, x2, y2, x, y) # rubocop: disable Metrics/ParameterLists
          @commands << [:curve, x1, y1, x2, y2, x, y]
        end

        # Close current contour.
        #
        # @return [void]
        def close_path
          @commands << CLOSE_PATH_CMD
          @number_of_contours += 1
        end

        # Reposition and scale path.
        #
        # @param x [Integer, Float] new horizontal position.
        # @param y [Integer, Float] new vertical position.
        # @param font_size [Integer, Float] font size.
        # @param units_per_em [Integer] units per Em as defined in the font.
        # @return [TTFunk::Table::Cff::Path]
        def render(x: 0, y: 0, font_size: 72, units_per_em: 1000)
          new_path = self.class.new
          scale = 1.0 / units_per_em * font_size

          commands.each do |cmd|
            case cmd[:type]
            when :move
              new_path.move_to(x + (cmd[1] * scale), y + (-cmd[2] * scale))
            when :line
              new_path.line_to(x + (cmd[1] * scale), y + (-cmd[2] * scale))
            when :curve
              new_path.curve_to(
                x + (cmd[1] * scale),
                y + (-cmd[2] * scale),
                x + (cmd[3] * scale),
                y + (-cmd[4] * scale),
                x + (cmd[5] * scale),
                y + (-cmd[6] * scale),
              )
            when :close
              new_path.close_path
            end
          end

          new_path
        end

        private

        def format_values(command)
          command[1..].map { |k| format('%.2f', k) }.join(' ')
        end
      end
    end
  end
end
