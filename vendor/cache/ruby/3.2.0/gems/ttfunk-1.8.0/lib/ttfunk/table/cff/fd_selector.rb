# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF FDSelect.
      class FdSelector < TTFunk::SubTable
        include Enumerable

        # Array format.
        ARRAY_FORMAT = 0

        # Range format.
        RANGE_FORMAT = 3

        # Range entry size.
        RANGE_ENTRY_SIZE = 3

        # Array entry size.
        ARRAY_ENTRY_SIZE = 1

        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # Number of encoded items.
        # @return [Integer]
        attr_reader :items_count

        # Number of entries.
        # @return [Array<Integer>] if format is array.
        # @return [Array<Array(Range, Integer)>] if format is range.
        attr_reader :entries

        # Number of glyphs.
        # @return [Integer]
        attr_reader :n_glyphs

        # @param top_dict [TTFunk::Table:Cff::TopDict]
        # @param file [TTFunk::File]
        # @param offset [Integer]
        # @param length [Integer]
        def initialize(top_dict, file, offset, length = nil)
          @top_dict = top_dict
          super(file, offset, length)
        end

        # Get font dict index for glyph ID.
        #
        # @return [Integer]
        def [](glyph_id)
          case format_sym
          when :array_format
            entries[glyph_id]

          when :range_format
            if (entry = range_cache[glyph_id])
              return entry
            end

            range, entry =
              entries.bsearch { |rng, _|
                if rng.cover?(glyph_id)
                  0
                elsif glyph_id < rng.first
                  -1
                else
                  1
                end
              }

            range.each { |i| range_cache[i] = entry }
            entry
          end
        end

        # Iterate over font dicts for each glyph ID.
        #
        # @yieldparam [Integer] font dict index.
        # @return [void]
        def each
          return to_enum(__method__) unless block_given?

          items_count.times { |i| yield(self[i]) }
        end

        # Encode Font dict selector.
        #
        # @param charmap [Hash{Integer => Hash}] keys are the charac codes,
        #   values are hashes:
        #   * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
        #   * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
        # @return [String]
        def encode(charmap)
          # get list of [new_gid, fd_index] pairs
          new_indices =
            charmap
              .reject { |code, mapping| mapping[:new].zero? && !code.zero? }
              .sort_by { |_code, mapping| mapping[:new] }
              .map { |(_code, mapping)| [mapping[:new], self[mapping[:old]]] }

          ranges = rangify_gids(new_indices)
          total_range_size = ranges.size * RANGE_ENTRY_SIZE
          total_array_size = new_indices.size * ARRAY_ENTRY_SIZE

          ''.b.tap do |result|
            if total_array_size <= total_range_size
              result << [ARRAY_FORMAT].pack('C')
              result << new_indices.map(&:last).pack('C*')
            else
              result << [RANGE_FORMAT, ranges.size].pack('Cn')
              ranges.each { |range| result << range.pack('nC') }

              # "A sentinel GID follows the last range element and serves to
              # delimit the last range in the array. (The sentinel GID is set
              # equal to the number of glyphs in the font. That is, its value
              # is 1 greater than the last GID in the font)."
              result << [new_indices.size].pack('n')
            end
          end
        end

        private

        def range_cache
          @range_cache ||= {}
        end

        # values is an array of [new_gid, fd_index] pairs
        def rangify_gids(values)
          start_gid = 0

          [].tap do |ranges|
            values.each_cons(2) do |(_, first_idx), (sec_gid, sec_idx)|
              if first_idx != sec_idx
                ranges << [start_gid, first_idx]
                start_gid = sec_gid
              end
            end

            ranges << [start_gid, values.last[1]]
          end
        end

        def parse!
          @format = read(1, 'C').first
          @length = 1

          case format_sym
          when :array_format
            @n_glyphs = top_dict.charstrings_index.items_count
            data = io.read(n_glyphs)
            @length += data.bytesize
            @items_count = data.bytesize
            @entries = data.bytes

          when :range_format
            # +2 for sentinel GID, +2 for num_ranges
            num_ranges = read(2, 'n').first
            @length += (num_ranges * RANGE_ENTRY_SIZE) + 4

            ranges = Array.new(num_ranges) { read(RANGE_ENTRY_SIZE, 'nC') }

            @entries =
              ranges.each_cons(2).map { |first, second|
                first_gid, fd_index = first
                second_gid, = second
                [(first_gid...second_gid), fd_index]
              }

            # read the sentinel GID, otherwise known as the number of glyphs
            # in the font
            @n_glyphs = read(2, 'n').first

            last_start_gid, last_fd_index = ranges.last
            @entries << [(last_start_gid...(n_glyphs + 1)), last_fd_index]

            @items_count = entries.reduce(0) { |sum, entry| sum + entry.first.size }
          end
        end

        def format_sym
          case @format
          when ARRAY_FORMAT then :array_format
          when RANGE_FORMAT then :range_format
          else
            raise Error, "unsupported fd select format '#{@format}'"
          end
        end
      end
    end
  end
end
