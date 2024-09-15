# frozen_string_literal: true

require_relative 'reader'

module TTFunk
  # SFNT table
  class Table
    include Reader

    # File this table is in.
    # @return [TTFunk::File]
    attr_reader :file

    # This table's offset from the file beginning.
    # @return [Integer]
    attr_reader :offset

    # This table's length in byes.
    # @return [Integer, nil]
    attr_reader :length

    # @param file [TTFunk::File]
    def initialize(file)
      @file = file
      @offset = nil
      @length = nil

      info = file.directory_info(tag)

      if info
        @offset = info[:offset]
        @length = info[:length]

        parse_from(@offset) { parse! }
      end
    end

    # Does this table exist in the file?
    #
    # @return [Boolean]
    def exists?
      !@offset.nil?
    end

    # Raw bytes of this table in the file.
    #
    # @return [String, nil]
    def raw
      if exists?
        parse_from(offset) { io.read(length) }
      end
    end

    # Table tag.
    #
    # @return [String]
    def tag
      self.class.name.split('::').last.downcase
    end

    private

    def parse!
      # do nothing, by default
    end
  end
end
