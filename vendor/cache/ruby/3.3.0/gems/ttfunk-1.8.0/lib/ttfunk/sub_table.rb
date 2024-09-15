# frozen_string_literal: true

require_relative 'reader'

module TTFunk
  # SFNT sub-table
  class SubTable
    # A read past sub-table end was attempted.
    class EOTError < StandardError
    end

    include Reader

    # File or IO this sub-table is in.
    # @return [IO]
    attr_reader :file

    # This sub-table's offset from the file beginning.
    # @return [Integer]
    attr_reader :table_offset

    # This sub-table's length in byes.
    # @return [Integer, nil]
    attr_reader :length

    # @param file [IO]
    # @param offset [Integer]
    # @param length [Integer]
    def initialize(file, offset, length = nil)
      @file = file
      @table_offset = offset
      @length = length
      parse_from(@table_offset) { parse! }
    end

    # End of sub-table?
    #
    # @return [Boolean]
    def eot?
      # if length isn't set yet there's no way to know if we're at the end of
      # the sub-table or not
      return false unless length

      io.pos > table_offset + length
    end

    # Read a series of values.
    #
    # @overload read(bytes, format)
    #   @param bytes [Integer] number of bytes to read.
    #   @param format [String] format to parse the bytes.
    #   @return [Array]
    #   @raise [EOTError]
    #   @see # Ruby Packed data
    def read(*args)
      if eot?
        raise EOTError, 'attempted to read past the end of the table'
      end

      super
    end
  end
end
