# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Encoding.
      class Encoding < TTFunk::SubTable
        include Enumerable

        # Predefined Standard Encoding ID.
        STANDARD_ENCODING_ID = 0

        # Predefined Expert Encoding ID.
        EXPERT_ENCODING_ID = 1

        # Default encoding ID.
        DEFAULT_ENCODING_ID = STANDARD_ENCODING_ID

        class << self
          # Get predefined encoding by ID.
          #
          # @param encoding_id [Integer]
          # @return [TTFunk::OneBasedArray<Integer>]
          def codes_for_encoding_id(encoding_id)
            case encoding_id
            when STANDARD_ENCODING_ID
              Encodings::STANDARD
            when EXPERT_ENCODING_ID
              Encodings::EXPERT
            end
          end
        end

        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # Encodign format.
        # @return [Integer]
        attr_reader :format

        # Number of encoded items.
        # @return [Integer]
        attr_reader :items_count

        # Offset or encoding ID.
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
        #   @param encoding_id [Integer] 0, 1, or 2
        def initialize(top_dict, file, offset_or_id = nil, length = nil)
          @top_dict = top_dict
          @offset_or_id = offset_or_id || DEFAULT_ENCODING_ID

          if offset
            super(file, offset, length)
            @supplemental = format >> 7 == 1
          else
            @items_count = self.class.codes_for_encoding_id(offset_or_id).size
            @supplemental = false
          end
        end

        # Iterate over character codes.
        #
        # @overload each()
        #   @yieldparam code [Integer]
        #   @return [void]
        # @overload each()
        #   @return [Enumerator]
        def each
          return to_enum(__method__) unless block_given?

          # +1 adjusts for the implicit .notdef glyph
          (items_count + 1).times { |i| yield(self[i]) }
        end

        # Get character code for glyph index.
        #
        # @param glyph_id [Integer]
        # @return [Integer, nil]
        def [](glyph_id)
          return 0 if glyph_id.zero?
          return code_for(glyph_id) if offset

          self.class.codes_for_encoding_id(offset_or_id)[glyph_id]
        end

        # Encoding offset in the file.
        #
        # @return [Integer, nil]
        def offset
          # Numbers from 0..1 mean encoding IDs instead of offsets. IDs are
          # pre-defined, generic encodings that define the characters present
          # in the font.
          #
          # In the case of an offset, add the CFF table's offset since the
          # charset offset is relative to the start of the CFF table. Otherwise
          # return nil (no offset).
          if offset_or_id > 1
            offset_or_id + top_dict.cff_offset
          end
        end

        # Encode encoding.
        #
        # @param charmap [Hash{Integer => Hash}] keys are the charac codes,
        #   values are hashes:
        #   * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
        #   * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
        # @return [String]
        def encode(charmap)
          # Any subset encoding is all but guaranteed to be different from the
          # standard encoding so we don't even attempt to see if it matches. We
          # assume it's different and just encode it anew.

          return encode_supplemental(charmap) if supplemental?

          codes =
            charmap
              .reject { |_code, mapping| mapping[:new].zero? }
              .sort_by { |_code, mapping| mapping[:new] }
              .map { |(code, _m)| code }

          ranges = TTFunk::BinUtils.rangify(codes)

          # calculate whether storing the charset as a series of ranges is
          # more efficient (i.e. takes up less space) vs storing it as an
          # array of SID values
          total_range_size = (2 * ranges.size) +
            (element_width(:range_format) * ranges.size)

          total_array_size = codes.size * element_width(:array_format)

          if total_array_size <= total_range_size
            ([format_int(:array_format), codes.size] + codes).pack('C*')
          else
            element_fmt = element_format(:range_format)
            result = [format_int(:range_format), ranges.size].pack('CC')
            ranges.each { |range| result << range.pack(element_fmt) }
            result
          end
        end

        # Is this a supplemental encoding?
        #
        # @return [Boolean]
        def supplemental?
          # high-order bit set to 1 indicates supplemental encoding
          @supplemental
        end

        private

        def encode_supplemental(charmap)
          new_entries =
            charmap
              .reject { |_code, mapping| mapping[:new].zero? }
              .transform_values { |mapping| mapping[:new] }

          result = [format_int(:supplemental), new_entries.size].pack('CC')
          fmt = element_format(:supplemental)

          new_entries.each do |code, new_gid|
            result << [code, new_gid].pack(fmt)
          end

          result
        end

        def code_for(glyph_id)
          return 0 if glyph_id.zero?

          # rather than validating the glyph as part of one of the predefined
          # encodings, just pass it through
          return glyph_id unless offset

          case format_sym
          when :array_format, :supplemental
            @entries[glyph_id]

          when :range_format
            remaining = glyph_id

            @entries.each do |range|
              if range.size >= remaining
                return (range.first + remaining) - 1
              end

              remaining -= range.size
            end

            0
          end
        end

        def parse!
          @format, entry_count = read(2, 'C*')
          @length = entry_count * element_width

          case format_sym
          when :array_format
            @items_count = entry_count
            @entries = OneBasedArray.new(read(length, 'C*'))

          when :range_format
            @entries = []
            @items_count = 0

            entry_count.times do
              code, num_left = read(element_width, element_format)
              @entries << (code..(code + num_left))
              @items_count += num_left + 1
            end

          when :supplemental
            @entries = {}
            @items_count = entry_count

            entry_count.times do
              code, glyph = read(element_width, element_format)
              @entries[code] = glyph
            end
          end
        end

        def element_format(fmt = format_sym)
          {
            array_format: 'C',
            range_format: 'CC',
            supplemental: 'Cn',
          }[fmt]
        end

        # @TODO: handle supplemental encoding (necessary?)
        def element_width(fmt = format_sym)
          case fmt
          when :array_format then 1
          when :range_format then 2
          when :supplemental then 3
          else
            raise Error, "'#{fmt}' is an unsupported encoding format"
          end
        end

        def format_sym
          return :supplemental if supplemental?

          case @format
          when 0 then :array_format
          when 1 then :range_format
          else
            raise Error, "unsupported charset format '#{fmt}'"
          end
        end

        def format_int(sym = format_sym)
          case sym
          when :array_format then 0
          when :range_format then 1
          when :supplemental then 129
          else
            raise Error, "unsupported charset format '#{sym}'"
          end
        end
      end
    end
  end
end
