# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Private dict.
      class PrivateDict < TTFunk::Table::Cff::Dict
        # Default value of Default Width X.
        DEFAULT_WIDTH_X_DEFAULT = 0

        # Default value of Nominal Width X.
        DEFAULT_WIDTH_X_NOMINAL = 0

        # Length of placeholders.
        PLACEHOLDER_LENGTH = 5

        # Operators we care about in this dict.
        OPERATORS = {
          subrs: 19,
          default_width_x: 20,
          nominal_width_x: 21,
        }.freeze

        # Inverse operator mapping.
        OPERATOR_CODES = OPERATORS.invert

        # Encode dict.
        #
        # @return [TTFunk::EncodedString]
        def encode
          # TODO: use mapping to determine which subroutines are still used.
          # For now, just encode them all.
          EncodedString.new do |result|
            each do |operator, operands|
              case OPERATOR_CODES[operator]
              when :subrs
                result << encode_subrs
              else
                operands.each { |operand| result << encode_operand(operand) }
              end

              result << encode_operator(operator)
            end
          end
        end

        # Finalize dict.
        #
        # @param private_dict_data [TTFunk::EncodedString]
        # @return [void]
        def finalize(private_dict_data)
          return unless subr_index

          encoded_subr_index = subr_index.encode
          encoded_offset = encode_integer32(private_dict_data.length)

          private_dict_data.resolve_placeholder(:"subrs_#{@table_offset}", encoded_offset)

          private_dict_data << encoded_subr_index
        end

        # Subroutine index.
        #
        # @return [TTFunk::Table::Cff::SubrIndex, nil]
        def subr_index
          @subr_index ||=
            if (subr_offset = self[OPERATORS[:subrs]])
              SubrIndex.new(file, table_offset + subr_offset.first)
            end
        end

        # Default Width X.
        #
        # @return [Integer]
        def default_width_x
          if (width = self[OPERATORS[:default_width_x]])
            width.first
          else
            DEFAULT_WIDTH_X_DEFAULT
          end
        end

        # Nominal Width X.
        #
        # @return [Integer]
        def nominal_width_x
          if (width = self[OPERATORS[:nominal_width_x]])
            width.first
          else
            DEFAULT_WIDTH_X_NOMINAL
          end
        end

        private

        def encode_subrs
          EncodedString.new do |result|
            result << Placeholder.new(:"subrs_#{@table_offset}", length: PLACEHOLDER_LENGTH)
          end
        end
      end
    end
  end
end
