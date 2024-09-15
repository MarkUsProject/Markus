# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF top dict.
      class TopDict < TTFunk::Table::Cff::Dict
        # Default charstring type.
        DEFAULT_CHARSTRING_TYPE = 2

        # Length of placeholders for pointer operators.
        POINTER_PLACEHOLDER_LENGTH = 5

        # Length of placeholders for other operators.
        PLACEHOLDER_LENGTH = 5

        # Operators whose values are offsets that point to other parts
        # of the file.
        POINTER_OPERATORS = {
          charset: 15,
          encoding: 16,
          charstrings_index: 17,
          private: 18,
          font_index: 1236,
          font_dict_selector: 1237,
        }.freeze

        # All the operators we currently care about.
        OPERATORS = {
          **POINTER_OPERATORS,
          ros: 1230,
          charstring_type: 1206,
        }.freeze

        # Inverse operator mapping.
        OPERATOR_CODES = OPERATORS.invert

        # Encode dict.
        #
        # @return [TTFunk::EncodedString]
        def encode(*)
          EncodedString.new do |result|
            each_with_index do |(operator, operands), _idx|
              if operator == OPERATORS[:private]
                result << encode_private
              elsif pointer_operator?(operator)
                result << Placeholder.new(
                  OPERATOR_CODES[operator],
                  length: POINTER_PLACEHOLDER_LENGTH,
                )
              else
                operands.each { |operand| result << encode_operand(operand) }
              end

              result << encode_operator(operator)
            end
          end
        end

        # Finalize the table.
        #
        # @param new_cff_data [TTFunk::EncodedString]
        # @param charmap [Hash{Integer => Hash}] keys are the charac codes,
        #   values are hashes:
        #   * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
        #   * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
        # @return [void]
        def finalize(new_cff_data, charmap)
          if charset
            finalize_subtable(new_cff_data, :charset, charset.encode(charmap))
          end

          if encoding
            finalize_subtable(new_cff_data, :encoding, encoding.encode(charmap))
          end

          if charstrings_index
            finalize_subtable(new_cff_data, :charstrings_index, charstrings_index.encode(charmap))
          end

          if font_index
            finalize_subtable(new_cff_data, :font_index, font_index.encode)

            font_index.finalize(new_cff_data)
          end

          if font_dict_selector
            finalize_subtable(new_cff_data, :font_dict_selector, font_dict_selector.encode(charmap))
          end

          if private_dict
            encoded_private_dict = private_dict.encode
            encoded_offset = encode_integer32(new_cff_data.length)
            encoded_length = encode_integer32(encoded_private_dict.length)

            new_cff_data.resolve_placeholder(:"private_length_#{@table_offset}", encoded_length)
            new_cff_data.resolve_placeholder(:"private_offset_#{@table_offset}", encoded_offset)

            private_dict.finalize(encoded_private_dict)
            new_cff_data << encoded_private_dict
          end
        end

        # Registry Ordering Supplement.
        #
        # @return [Array(Integer, Integer, Integer), nil]
        def ros
          self[OPERATORS[:ros]]
        end

        # Is Registry Ordering Supplement present in this dict?
        #
        # @return [Boolean]
        def ros?
          !ros.nil?
        end

        alias is_cid_font? ros?

        # Charset specified in this dict.
        #
        # @return [TTFunk::Table::Cff::Charset, nil]
        def charset
          @charset ||=
            if (charset_offset_or_id = self[OPERATORS[:charset]])
              if charset_offset_or_id.empty?
                Charset.new(self, file)
              else
                Charset.new(self, file, charset_offset_or_id.first)
              end
            end
        end

        # Encoding specified in this dict.
        #
        # @return [TTFunk::Table::Cff::Encoding, nil]
        def encoding
          # PostScript type 1 fonts, i.e. CID fonts, i.e. some fonts that use
          # the CFF table, don't specify an encoding, so this can be nil
          @encoding ||=
            if (encoding_offset_or_id = self[OPERATORS[:encoding]])
              Encoding.new(self, file, encoding_offset_or_id.first)
            end
        end

        # Charstrings index specified in this dict.
        #
        # > OpenType fonts with TrueType outlines use a glyph index to specify
        #   and access glyphs within a font; e.g., to index within the `loca`
        #   table and thereby access glyph data in the `glyf` table. This
        #   concept is retained in OpenType CFF fonts, except that glyph data is
        #   accessed through the CharStrings INDEX of the CFF table.
        #
        # > --- [CFF — Compact Font Format Table](https://www.microsoft.com/typography/otspec/cff.htm)
        #
        # @return [TTFunk::Table::Cff::CharstringsIndex, nil]
        def charstrings_index
          @charstrings_index ||=
            if (charstrings_offset = self[OPERATORS[:charstrings_index]])
              CharstringsIndex.new(self, file, cff_offset + charstrings_offset.first)
            end
        end

        # Charstring type specified in this dict.
        #
        # @return [Integer]
        def charstring_type
          @charstring_type =
            self[OPERATORS[:charstring_type]] || DEFAULT_CHARSTRING_TYPE
        end

        # Font index specified in this dict.
        #
        # @return [TTFunk::Table::Cff::FontIndex, nil]
        def font_index
          @font_index ||=
            if (font_index_offset = self[OPERATORS[:font_index]])
              FontIndex.new(self, file, cff_offset + font_index_offset.first)
            end
        end

        # Font dict selector specified in this dict.
        #
        # @return [TTFunk::Table::Cff::FdSelector, nil]
        def font_dict_selector
          @font_dict_selector ||=
            if (fd_select_offset = self[OPERATORS[:font_dict_selector]])
              FdSelector.new(self, file, cff_offset + fd_select_offset.first)
            end
        end

        # Private dict specified in this dict.
        #
        # @return [TTFunk::Table::Cff::PrivateDict, nil]
        def private_dict
          @private_dict ||=
            if (info = self[OPERATORS[:private]])
              private_dict_length, private_dict_offset = info

              PrivateDict.new(file, cff_offset + private_dict_offset, private_dict_length)
            end
        end

        # CFF table in this file.
        #
        # @return [TTFunk::Table::Cff]
        def cff
          file.cff
        end

        # Ofsset of CFF table in the file.
        #
        # @return [Integer]
        def cff_offset
          cff.offset
        end

        private

        def encode_private
          EncodedString.new do |result|
            result << Placeholder.new(
              :"private_length_#{@table_offset}",
              length: PLACEHOLDER_LENGTH,
            )

            result << Placeholder.new(
              :"private_offset_#{@table_offset}",
              length: PLACEHOLDER_LENGTH,
            )
          end
        end

        def finalize_subtable(new_cff_data, name, table_data)
          encoded = encode_integer32(new_cff_data.length)
          new_cff_data.resolve_placeholder(name, encoded)
          new_cff_data << table_data
        end

        def pointer_operator?(operator)
          POINTER_OPERATORS.include?(OPERATOR_CODES[operator])
        end

        def encode_charstring_type(charstring_type)
          if charstring_type == DEFAULT_CHARSTRING_TYPE
            ''
          else
            encode_operand(charstring_type)
          end
        end
      end
    end
  end
end
