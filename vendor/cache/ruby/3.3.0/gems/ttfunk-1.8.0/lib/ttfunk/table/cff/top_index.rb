# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Index conatining Top dict.
      class TopIndex < TTFunk::Table::Cff::Index
        private

        def decode_item(_index, offset, length)
          TTFunk::Table::Cff::TopDict.new(file, offset, length)
        end

        def encode_items(*)
          # Re-encode the top dict
          map(&:encode)
        end
      end
    end
  end
end
