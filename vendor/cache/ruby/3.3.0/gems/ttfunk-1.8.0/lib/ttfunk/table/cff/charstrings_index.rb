# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Charstrings Index.
      class CharstringsIndex < TTFunk::Table::Cff::Index
        # Top dict.
        # @return [TTFunk::Table::Cff::TopDict]
        attr_reader :top_dict

        # @overload initialize(top_dict, file, offset, length = nil)
        #   @param top_dict [TTFunk::Table:Cff::TopDict]
        #   @param file [TTFunk::File]
        #   @param offset [Integer]
        #   @param length [Integer]
        def initialize(top_dict, *remaining_args)
          super(*remaining_args)
          @top_dict = top_dict
        end

        private

        def decode_item(index, _offset, _length)
          TTFunk::Table::Cff::Charstring.new(index, top_dict, font_dict_for(index), super)
        end

        def encode_items(charmap)
          charmap
            .reject { |code, mapping| mapping[:new].zero? && !code.zero? }
            .sort_by { |_code, mapping| mapping[:new] }
            .map { |(_code, mapping)| items[mapping[:old]] }
        end

        def font_dict_for(index)
          # only CID-keyed fonts contain an FD selector and font dicts
          if top_dict.is_cid_font?
            fd_index = top_dict.font_dict_selector[index]
            top_dict.font_index[fd_index]
          end
        end
      end
    end
  end
end
