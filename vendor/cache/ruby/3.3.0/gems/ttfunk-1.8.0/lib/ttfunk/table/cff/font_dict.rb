# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Font dict.
      class FontDict < TTFunk::Table::Cff::Dict
        # Length of placeholders.
        PLACEHOLDER_LENGTH = 5

        # Operators we care about in this dict.
        OPERATORS = { private: 18 }.freeze

        # Inverse operator mapping.
        OPERATOR_CODES = OPERATORS.invert

        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # @param top_dict [TTFunk::Table:Cff::TopDict]
        # @param file [TTFunk::File]
        # @param offset [Integer]
        # @param length [Integer]
        def initialize(top_dict, file, offset, length = nil)
          @top_dict = top_dict
          super(file, offset, length)
        end

        # Encode dict.
        #
        # @return [TTFunk::EncodedString]
        def encode
          EncodedString.new do |result|
            each do |operator, operands|
              case OPERATOR_CODES[operator]
              when :private
                result << encode_private
              else
                operands.each { |operand| result << encode_operand(operand) }
              end

              result << encode_operator(operator)
            end
          end
        end

        # Finalize dict.
        #
        # @param new_cff_data [TTFunk::EncodedString]
        # @return [void]
        def finalize(new_cff_data)
          encoded_private_dict = private_dict.encode
          encoded_offset = encode_integer32(new_cff_data.length)
          encoded_length = encode_integer32(encoded_private_dict.length)

          new_cff_data.resolve_placeholder(:"private_length_#{@table_offset}", encoded_length)
          new_cff_data.resolve_placeholder(:"private_offset_#{@table_offset}", encoded_offset)

          private_dict.finalize(encoded_private_dict)
          new_cff_data << encoded_private_dict
        end

        # Private dict.
        #
        # @return [TTFunk::Table::Cff::PrivateDict, nil]
        def private_dict
          @private_dict ||=
            if (info = self[OPERATORS[:private]])
              private_dict_length, private_dict_offset = info

              PrivateDict.new(
                file,
                top_dict.cff_offset + private_dict_offset,
                private_dict_length,
              )
            end
        end

        private

        def encode_private
          EncodedString.new do |result|
            result << Placeholder.new(:"private_length_#{@table_offset}", length: PLACEHOLDER_LENGTH)
            result << Placeholder.new(:"private_offset_#{@table_offset}", length: PLACEHOLDER_LENGTH)
          end
        end
      end
    end
  end
end
