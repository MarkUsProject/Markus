# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Font Dict Index.
      class FontIndex < TTFunk::Table::Cff::Index
        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # @param top_dict [TTFunk::Table:Cff::TopDict]
        # @param file [TTFunk::File]
        # @param offset [Integer]
        # @param length [Integer]
        def initialize(top_dict, file, offset, length = nil)
          super(file, offset, length)
          @top_dict = top_dict
        end

        # Finalize index.
        #
        # @param new_cff_data [TTFunk::EncodedString]
        # @return [void]
        def finalize(new_cff_data)
          each { |font_dict| font_dict.finalize(new_cff_data) }
        end

        private

        def decode_item(_index, offset, length)
          TTFunk::Table::Cff::FontDict.new(top_dict, file, offset, length)
        end

        def encode_items(*)
          # Re-encode font dicts
          map(&:encode)
        end
      end
    end
  end
end
