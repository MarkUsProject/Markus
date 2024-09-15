# frozen_string_literal: true

module TTFunk
  # Array with indexing starting at 1.
  class OneBasedArray
    include Enumerable

    # @overload initialize(size)
    #   @param size [Integer] number of entries in this array
    # @overload initialize(entries)
    #   @param entries [Array] an array to take entries from
    def initialize(size = 0)
      @entries = Array.new(size)
    end

    # Get element by index.
    #
    # @param idx [Integer]
    # @return [any, nil]
    # @raise IndexError if index is 0
    def [](idx)
      if idx.zero?
        raise IndexError,
          "index #{idx} was outside the bounds of the array"
      end

      entries[idx - 1]
    end

    # Number of elements in this array.
    #
    # @return [Integer]
    def size
      entries.size
    end

    # Convert to native array.
    #
    # @return [Array]
    def to_ary
      entries
    end

    # Iterate over elements.
    #
    # @yieldparam element [any]
    # @return [void]
    def each(&block)
      entries.each(&block)
    end

    private

    attr_reader :entries
  end
end
