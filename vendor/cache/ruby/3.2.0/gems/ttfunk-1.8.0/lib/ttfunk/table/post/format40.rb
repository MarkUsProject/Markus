# frozen_string_literal: true

module TTFunk
  class Table
    class Post
      # Version 4.0 names glyphs by their character code.
      module Format40
        # Get glyph name for character code.
        #
        # @param code [Integer]
        # @return [String]
        def glyph_for(code)
          @map[code] || 0xFFFF
        end

        private

        def parse_format!
          @map = read(file.maximum_profile.num_glyphs * 2, 'N*')
        end
      end
    end
  end
end
