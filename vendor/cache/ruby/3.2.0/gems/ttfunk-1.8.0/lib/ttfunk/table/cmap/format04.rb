# frozen_string_literal: true

module TTFunk
  class Table
    class Cmap
      # Format 4: Segment mapping to delta values.
      #
      # This module conditionally extends {TTFunk::Table::Cmap::Subtable}.
      module Format04
        # Language.
        # @return [Integer]
        attr_reader :language

        # Code map.
        # @return [Hash{Integer => Integer}]
        attr_reader :code_map

        # Encode the encoding record to format 4.
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
          end_codes = []
          start_codes = []
          next_id = 0
          last = difference = nil

          glyph_map = { 0 => 0 }
          new_map =
            charmap.keys.sort.each_with_object({}) do |code, map|
              old = charmap[code]
              glyph_map[old] ||= next_id += 1
              map[code] = { old: old, new: glyph_map[old] }

              delta = glyph_map[old] - code
              if last.nil? || delta != difference
                end_codes << last if last
                start_codes << code
                difference = delta
              end
              last = code

              map
            end

          end_codes << last if last
          end_codes << 0xFFFF
          start_codes << 0xFFFF
          segcount = start_codes.length

          # build the conversion tables
          deltas = []
          range_offsets = []
          glyph_indices = []
          offset = 0

          start_codes.zip(end_codes).each_with_index do |(a, b), segment|
            if a == 0xFFFF
              # We want the final 0xFFFF code to map to glyph 0.
              # The glyph index is calculated as glyph = charcode + delta,
              # which means that delta must be -0xFFFF to map character code
              # 0xFFFF to glyph 0.
              deltas << -0xFFFF
              range_offsets << 0
              break
            end

            start_glyph_id = new_map[a][:new]

            if a - start_glyph_id >= 0x8000
              deltas << 0
              range_offsets << (2 * (glyph_indices.length + segcount - segment))
              a.upto(b) { |code| glyph_indices << new_map[code][:new] }
            else
              deltas << (-a + start_glyph_id)
              range_offsets << 0
            end

            offset += 2
          end

          # format, length, language
          subtable = [
            4, 16 + (8 * segcount) + (2 * glyph_indices.length), 0,
          ].pack('nnn')

          search_range = 2 * (2**Integer(Math.log(segcount) / Math.log(2)))
          entry_selector = Integer(Math.log(search_range / 2) / Math.log(2))
          range_shift = (2 * segcount) - search_range
          subtable << [
            segcount * 2, search_range, entry_selector, range_shift,
          ].pack('nnnn')

          subtable << end_codes.pack('n*') << "\0\0" << start_codes.pack('n*')
          subtable << deltas.pack('n*') << range_offsets.pack('n*')
          subtable << glyph_indices.pack('n*')

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
          length, @language, segcount_x2 = read(6, 'nnn')
          segcount = segcount_x2 / 2

          io.read(6) # skip searching hints

          end_code = read(segcount_x2, 'n*')
          io.read(2) # skip reserved value
          start_code = read(segcount_x2, 'n*')
          id_delta = read_signed(segcount)
          id_range_offset = read(segcount_x2, 'n*')

          glyph_ids = read(length - io.pos + @offset, 'n*')

          @code_map = {}

          end_code.each_with_index do |tail, i|
            start_code[i].upto(tail) do |code|
              if (id_range_offset[i]).zero?
                glyph_id = code + id_delta[i]
              else
                index = (id_range_offset[i] / 2) + (code - start_code[i]) - (segcount - i)
                # Because some TTF fonts are broken
                glyph_id = glyph_ids[index] || 0
                glyph_id += id_delta[i] if glyph_id != 0
              end

              @code_map[code] = glyph_id & 0xFFFF
            end
          end
        end
      end
    end
  end
end
