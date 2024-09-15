# frozen_string_literal: true

module TTFunk # rubocop: disable Style/Documentation # false positive
  # Bit crunching utility methods.
  module BinUtils
    # Turn a bunch of small integers into one big integer. Assumes big-endian.
    #
    # @param arr [Array<Integer>]
    # @param bit_width [Integer] bit width of the elements
    # @return [Integer]
    def stitch_int(arr, bit_width:)
      value = 0

      arr.each_with_index do |element, index|
        value |= element << (bit_width * index)
      end

      value
    end

    # Slice a big integer into a bunch of small integers. Assumes big-endian.
    #
    # @param value [Integer]
    # @param bit_width [Integer] bit width of the elements
    # @param slice_count [Integer] number of elements to slice into. This is
    #   needed for cases where top bits are zero.
    # @return [Array<Integer>]
    def slice_int(value, bit_width:, slice_count:)
      mask = (2**bit_width) - 1

      Array.new(slice_count) do |i|
        (value >> (bit_width * i)) & mask
      end
    end

    # Two's compliment to an integer.
    #
    # @param num [Integer]
    # @param bit_width [Integer] number width
    # @return [Integer]
    def twos_comp_to_int(num, bit_width:)
      if num >> (bit_width - 1) == 1
        # we want all ones
        mask = (2**bit_width) - 1

        # find 2's complement, i.e. flip bits (xor with mask) and add 1
        -((num ^ mask) + 1)
      else
        num
      end
    end

    # Turns a (sorted) sequence of values into a series of two-element arrays
    # where the first element is the start and the second is the length.
    #
    # @param values [Array<Integer>]
    # @return [Array<Array(Integer, Integer)>]
    def rangify(values)
      values
        .slice_when { |a, b| b - a > 1 }
        .map { |span| [span.first, span.length - 1] }
    end
  end

  BinUtils.extend(BinUtils)
end
