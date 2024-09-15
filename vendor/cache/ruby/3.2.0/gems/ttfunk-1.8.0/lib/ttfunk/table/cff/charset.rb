# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Charset
      class Charset < TTFunk::SubTable
        include Enumerable

        # First glyph string. This is an implicit glyph present in all charsets.
        FIRST_GLYPH_STRING = '.notdef'

        # Format 0.
        ARRAY_FORMAT = 0

        # Format 1.
        RANGE_FORMAT_8 = 1

        # Format 2.
        RANGE_FORMAT_16 = 2

        # Predefined ISOAdobe charset ID.
        ISO_ADOBE_CHARSET_ID = 0

        # Predefined Expert charset ID.
        EXPERT_CHARSET_ID = 1

        # Predefined Expert Subset charset ID.
        EXPERT_SUBSET_CHARSET_ID = 2

        # Default charset ID.
        DEFAULT_CHARSET_ID = ISO_ADOBE_CHARSET_ID

        class << self
          # Standard strings defined in the spec that do not need to be defined
          # in the CFF.
          #
          # @return [TTFunk::OneBasedArray<String>]
          def standard_strings
            Charsets::STANDARD_STRINGS
          end

          # Strings for charset ID.
          #
          # @param charset_id [Integer]
          # @return [TTFunk::OneBasedArray<String>]
          def strings_for_charset_id(charset_id)
            case charset_id
            when ISO_ADOBE_CHARSET_ID
              Charsets::ISO_ADOBE
            when EXPERT_CHARSET_ID
              Charsets::EXPERT
            when EXPERT_SUBSET_CHARSET_ID
              Charsets::EXPERT_SUBSET
            end
          end
        end

        # Encoded entries.
        # @return [TTFunk::OneBasedArray<Integer>, Array<Range<Integer>>]
        attr_reader :entries

        # Length of encoded charset subtable.
        # @return [Integer]
        attr_reader :length

        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # Encodign format.
        # @return [Integer]
        attr_reader :format

        # Number of encoded items.
        # @return [Integer]
        attr_reader :items_count

        # Offset or charset ID.
        # @return [Integer]
        attr_reader :offset_or_id

        # @overload initialize(top_dict, file, offset = nil, length = nil)
        #   @param top_dict [TTFunk::Table:Cff::TopDict]
        #   @param file [TTFunk::File]
        #   @param offset [Integer]
        #   @param length [Integer]
        # @overload initialize(top_dict, file, charset_id)
        #   @param top_dict [TTFunk::Table:Cff::TopDict]
        #   @param file [TTFunk::File]
        #   @param charset_id [Integer] 0, 1, or 2
        def initialize(top_dict, file, offset_or_id = nil, length = nil)
          @top_dict = top_dict
          @offset_or_id = offset_or_id || DEFAULT_CHARSET_ID

          if offset
            super(file, offset, length)
          else
            @items_count = self.class.strings_for_charset_id(offset_or_id).size
          end
        end

        # Iterate over character names.
        #
        # @overload each()
        #   @yieldparam name [String]
        #   @return [void]
        # @overload each()
        #   @return [Enumerator]
        def each
          return to_enum(__method__) unless block_given?

          # +1 adjusts for the implicit .notdef glyph
          (items_count + 1).times { |i| yield(self[i]) }
        end

        # Get character name for glyph index.
        #
        # @param glyph_id [Integer]
        # @return [String, nil]
        def [](glyph_id)
          return FIRST_GLYPH_STRING if glyph_id.zero?

          find_string(sid_for(glyph_id))
        end

        # Charset offset in the file.
        #
        # @return [Integer, nil]
        def offset
          # Numbers from 0..2 mean charset IDs instead of offsets. IDs are
          # basically pre-defined sets of characters.
          #
          # In the case of an offset, add the CFF table's offset since the
          # charset offset is relative to the start of the CFF table. Otherwise
          # return nil (no offset).
          if offset_or_id > 2
            offset_or_id + top_dict.cff_offset
          end
        end

        # Encode charset.
        #
        # @param charmap [Hash{Integer => Hash}] keys are the charac codes,
        #   values are hashes:
        #   * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
        #   * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
        # @return [String]
        def encode(charmap)
          # no offset means no charset was specified (i.e. we're supposed to
          # use a predefined charset) so there's nothing to encode
          return '' unless offset

          sids =
            charmap
              .values
              .reject { |mapping| mapping[:new].zero? }
              .sort_by { |mapping| mapping[:new] }
              .map { |mapping| sid_for(mapping[:old]) }

          ranges = TTFunk::BinUtils.rangify(sids)
          range_max = ranges.map(&:last).max

          range_bytes =
            if range_max.positive?
              (Math.log2(range_max) / 8).floor + 1
            else
              # for cases when there are no sequences at all
              Float::INFINITY
            end

          # calculate whether storing the charset as a series of ranges is
          # more efficient (i.e. takes up less space) vs storing it as an
          # array of SID values
          total_range_size = (2 * ranges.size) + (range_bytes * ranges.size)
          total_array_size = sids.size * element_width(:array_format)

          if total_array_size <= total_range_size
            ([format_int(:array_format)] + sids).pack('Cn*')
          else
            fmt = range_bytes == 1 ? :range_format8 : :range_format16
            element_fmt = element_format(fmt)
            result = [format_int(fmt)].pack('C')
            ranges.each { |range| result << range.pack(element_fmt) }
            result
          end
        end

        private

        def sid_for(glyph_id)
          return 0 if glyph_id.zero?

          # rather than validating the glyph as part of one of the predefined
          # charsets, just pass it through
          return glyph_id unless offset

          case format_sym
          when :array_format
            entries[glyph_id]

          when :range_format8, :range_format16
            entries.reduce(glyph_id) do |remaining, range|
              if range.size >= remaining
                break (range.first + remaining) - 1
              end

              remaining - range.size
            end
          end
        end

        def find_string(sid)
          if offset
            return self.class.standard_strings[sid] if sid <= 390

            idx = sid - 390

            if idx < file.cff.string_index.items_count
              file.cff.string_index[idx]
            end
          else
            self.class.strings_for_charset_id(offset_or_id)[sid]
          end
        end

        def parse!
          return unless offset

          @format = read(1, 'C').first

          case format_sym
          when :array_format
            @items_count = top_dict.charstrings_index.items_count - 1
            @length = @items_count * element_width
            @entries = OneBasedArray.new(read(length, 'n*'))

          when :range_format8, :range_format16
            # The number of ranges is not explicitly specified in the font.
            # Instead, software utilizing this data simply processes ranges
            # until all glyphs in the font are covered.
            @items_count = 0
            @entries = []
            @length = 0

            until @items_count >= top_dict.charstrings_index.items_count - 1
              @length += 1 + element_width
              sid, num_left = read(element_width, element_format)
              @entries << (sid..(sid + num_left))
              @items_count += num_left + 1
            end
          end
        end

        def element_width(fmt = format_sym)
          {
            array_format: 2, # SID
            range_format8: 3, # SID + Card8
            range_format16: 4, # SID + Card16
          }[fmt]
        end

        def element_format(fmt = format_sym)
          {
            array_format: 'n',
            range_format8: 'nC',
            range_format16: 'nn',
          }[fmt]
        end

        def format_sym
          case @format
          when ARRAY_FORMAT then :array_format
          when RANGE_FORMAT_8 then :range_format8
          when RANGE_FORMAT_16 then :range_format16
          else
            raise Error, "unsupported charset format '#{fmt}'"
          end
        end

        def format_int(sym = format_sym)
          {
            array_format: ARRAY_FORMAT,
            range_format8: RANGE_FORMAT_8,
            range_format16: RANGE_FORMAT_16,
          }[sym]
        end
      end
    end
  end
end
