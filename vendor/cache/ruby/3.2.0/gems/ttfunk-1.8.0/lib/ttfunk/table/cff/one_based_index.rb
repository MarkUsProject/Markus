# frozen_string_literal: true

require 'forwardable'

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # CFF Index with indexing starting at 1.
      class OneBasedIndex
        extend Forwardable

        def_delegators :base_index,
          :each,
          :table_offset,
          :items_count,
          :length,
          :encode

        # Underlaying Index.
        # @return [TTFunk::Table::Cff::Index]
        attr_reader :base_index

        # @param args [Array] all params are passed to the base index.
        # @see Index
        def initialize(*args)
          @base_index = Index.new(*args)
        end

        # Get item by index.
        #
        # @param idx [Integer]
        # @return [any]
        # @raise [IndexError] when requested index is 0.
        def [](idx)
          if idx.zero?
            raise IndexError,
              "index #{idx} was outside the bounds of the index"
          end

          base_index[idx - 1]
        end
      end
    end
  end
end
