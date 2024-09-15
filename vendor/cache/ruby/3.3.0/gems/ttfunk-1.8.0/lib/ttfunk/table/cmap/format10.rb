# frozen_string_literal: true

module TTFunk
  class Table
    class Cmap
      # Format 10: Trimmed array.
      #
      # This module conditionally extends {TTFunk::Table::Cmap::Subtable}.
      module Format10
        # Language.
        # @return [Integer]
        attr_reader :language

        # Code map.
        # @return [Hash{Integer => Integer}]
        attr_reader :code_map

        # Encode the encoding record to format 10.
        #
        # @param charmap [Hash{Integer => Integer}] a hash mapping character
        #   codes to glyph IDs from the original font.
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
          glyph_map = { 0 => 0 }

          sorted_chars = charmap.keys.sort
          low_char = sorted_chars.first
          high_char = sorted_chars.last
          entry_count = 1 + high_char - low_char
          glyph_indexes = Array.new(entry_count, 0)

          new_map =
            charmap.keys.sort.each_with_object({}) do |code, map|
              glyph_map[charmap[code]] ||= next_id += 1
              map[code] = { old: charmap[code], new: glyph_map[charmap[code]] }
              glyph_indexes[code - low_char] = glyph_map[charmap[code]]
            end

          subtable = [
            10, 0, 20 + (entry_count * 4), 0, low_char, entry_count,
            *glyph_indexes,
          ].pack('nnN*')

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
          fractional_version, @language, firstcode, entrycount =
            read(18, 'nx4NNN')
          if fractional_version != 0
            raise NotImplementedError,
              "cmap version 10.#{fractional_version} is not supported"
          end
          @code_map = {}
          (firstcode...(firstcode + entrycount)).each do |code|
            @code_map[code] = read(2, 'n').first & 0xFFFF
          end
        end
      end
    end
  end
end
