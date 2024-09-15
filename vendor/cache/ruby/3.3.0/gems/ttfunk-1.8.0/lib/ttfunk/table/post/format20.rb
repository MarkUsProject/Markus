# frozen_string_literal: true

require_relative 'format10'
require 'stringio'

module TTFunk
  class Table
    class Post
      # Version 2.0 is used for fonts that use glyph names that are not in the
      # set of Macintosh glyph names. A given font may map some of its glyphs to
      # the standard Macintosh glyph names, and some to its own custom names.
      # A version 2.0 `post` table can be used in fonts with TrueType or CFF
      # version 2 outlines.
      module Format20
        include Format10

        # Get glyph name for character code.
        #
        # @param code [Integer]
        # @return [String]
        def glyph_for(code)
          index = @glyph_name_index[code]
          return '.notdef' unless index

          if index <= 257
            POSTSCRIPT_GLYPHS[index]
          else
            @names[index - 258] || '.notdef'
          end
        end

        private

        def parse_format!
          number_of_glyphs = read(2, 'n').first
          @glyph_name_index = read(number_of_glyphs * 2, 'n*')
          @names = []

          strings = StringIO.new(io.read(offset + length - io.pos))
          until strings.eof?
            length = strings.read(1).unpack1('C')
            @names << strings.read(length)
          end
        end
      end
    end
  end
end
