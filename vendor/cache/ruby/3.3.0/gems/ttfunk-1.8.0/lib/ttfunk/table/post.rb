# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # PostScript (`post`) table.
    #
    # This class can be extended with version-specific modules.
    #
    # @see TTFunk::Table::Post::Format10
    # @see TTFunk::Table::Post::Format20
    # @see TTFunk::Table::Post::Format30
    # @see TTFunk::Table::Post::Format40
    class Post < Table
      # Table version.
      # @return [Integer]
      attr_reader :format

      # Italic angle in counter-clockwise degrees from the vertical.
      # @return [Integer]
      attr_reader :italic_angle

      # Suggested distance of the top of the underline from the baseline
      # @return [Integer]
      attr_reader :underline_position

      # Suggested values for the underline thickness.
      # @return [Integer]
      attr_reader :underline_thickness

      # 0 if the font is proportionally spaced, non-zero if the font is not
      # proportionally spaced.
      # @return [Integer]
      attr_reader :fixed_pitch

      # Minimum memory usage when an OpenType font is downloaded.
      # @return [Integer]
      attr_reader :min_mem_type42

      # Maximum memory usage when an OpenType font is downloaded.
      # @return [Integer]
      attr_reader :max_mem_type42

      # Minimum memory usage when an OpenType font is downloaded as
      # a Type 1 font.
      # @return [Integer]
      attr_reader :min_mem_type1

      # Maximum memory usage when an OpenType font is downloaded as
      # a Type 1 font.
      # @return [Integer]
      attr_reader :max_mem_type1

      # Version-specific fields.
      # @return [TTFunk::Table::Post::Format10, TTFunk::Table::Post::Format20,
      #   TTFunk::Table::Post::Format30, TTFunk::Table::Post::Format40]
      attr_reader :subtable

      # Encode table.
      #
      # @param post [TTFunk::Table::Post]
      # @param mapping [Hash{Integer => Integer}] keys are new glyph IDs, values
      #   are old glyph IDs
      # @return [String, nil]
      def self.encode(post, mapping)
        return if post.nil?

        post.recode(mapping)
      end

      # Is this font monospaced?
      #
      # @return [Boolean]
      def fixed_pitch?
        @fixed_pitch != 0
      end

      # Get glyph name for character code.
      #
      # This is a placeholder.
      #
      # @param _code [Integer]
      # @return [String]
      def glyph_for(_code)
        '.notdef'
      end

      # Re-encode this table.
      #
      # @param mapping [Hash{Integer => Integer}] keys are new glyph IDs, values
      #   are old glyph IDs
      # @return [String]
      def recode(mapping)
        return raw if format == 0x00030000

        table = raw[0, 32]
        table[0, 4] = [0x00020000].pack('N')

        index = []
        strings = []

        mapping.keys.sort.each do |new_id|
          post_glyph = glyph_for(mapping[new_id])
          position = Format10::POSTSCRIPT_GLYPHS.index(post_glyph)
          if position
            index << position
          else
            index << (257 + strings.length)
            strings << post_glyph
          end
        end

        table << [mapping.length, *index].pack('n*')
        strings.each do |string|
          table << [string.length, string].pack('CA*')
        end

        table
      end

      private

      def parse!
        @format, @italic_angle, @underline_position, @underline_thickness,
          @fixed_pitch, @min_mem_type42, @max_mem_type42,
          @min_mem_type1, @max_mem_type1 = read(32, 'N2n2N*')

        @subtable =
          case @format
          when 0x00010000
            extend(Post::Format10)
          when 0x00020000
            extend(Post::Format20)
          when 0x00025000
            raise NotImplementedError,
              'Post format 2.5 is not supported by TTFunk'
          when 0x00030000
            extend(Post::Format30)
          when 0x00040000
            extend(Post::Format40)
          end

        parse_format!
      end

      def parse_format!
        warn(Kernel.format('postscript table format 0x%08X is not supported', @format))
      end
    end
  end
end

require_relative 'post/format10'
require_relative 'post/format20'
require_relative 'post/format30'
require_relative 'post/format40'
