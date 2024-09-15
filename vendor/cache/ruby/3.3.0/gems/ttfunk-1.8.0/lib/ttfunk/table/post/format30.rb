# frozen_string_literal: true

module TTFunk
  class Table
    class Post
      # Version 3.0 specifies that no PostScript name information is provided
      # for the glyphs in this font file.
      module Format30
        # Get glyph name for character code.
        #
        # @param _code [Integer]
        # @return [String]
        def glyph_for(_code)
          '.notdef'
        end

        private

        def parse_format!
          # do nothing. Format 3 is easy-sauce.
        end
      end
    end
  end
end
