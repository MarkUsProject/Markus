# frozen_string_literal: true

module TTFunk
  class Table
    class Cmap
      # Format 0: Byte encoding table.
      #
      # This module conditionally extends {TTFunk::Table::Cmap::Subtable}.
      module Format00
        # Language.
        # @return [Integer]
        attr_reader :language

        # Code map.
        # @return [Array<Integer>]
        attr_reader :code_map

        # Encode the encoding record to format 0.
        #
        # @param charmap [Hash{Integer => Integer}] a hash mapping character
        #   codes to glyph ids (where the glyph ids are from the original font).
        # @return [Hash]
        #   * `:charmap` (<tt>Hash{Integer => Hash}</tt>) keys are the characrers in
        #     `charset`, values are hashes:
        #     * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
        #     * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
        #     that maps the characters in charmap to a
        #   * `:subtable` (<tt>String</tt>) - serialized encoding record.
        #   * `:max_glyph_id` (<tt>Integer</tt>) - maximum glyph ID in the new font.
        def self.encode(charmap)
          next_id = 0
          glyph_indexes = Array.new(256, 0)
          glyph_map = { 0 => 0 }

          new_map =
            charmap.keys.sort.each_with_object({}) do |code, map|
              glyph_map[charmap[code]] ||= next_id += 1
              map[code] = { old: charmap[code], new: glyph_map[charmap[code]] }
              glyph_indexes[code] = glyph_map[charmap[code]]
              map
            end

          # format, length, language, indices
          subtable = [0, 262, 0, *glyph_indexes].pack('nnnC*')

          { charmap: new_map, subtable: subtable, max_glyph_id: next_id + 1 }
        end

        # Get glyph ID for character code.
        #
        # @param code [Integer] character code.
        # @return [Integer] glyph ID.
        def [](code)
          @code_map[code] || 0
        end

        # Is this encoding record format supported?
        #
        # @return [true]
        def supported?
          true
        end

        private

        def parse_cmap!
          @language = read(4, 'x2n')
          @code_map = read(256, 'C*')
        end
      end
    end
  end
end
