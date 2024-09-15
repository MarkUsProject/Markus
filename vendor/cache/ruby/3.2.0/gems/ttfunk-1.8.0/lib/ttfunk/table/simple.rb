# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    # A table that TTFunk doesn't decode but preserve.
    class Simple < Table
      # Table tag
      # @return [String]
      attr_reader :tag

      # @param file [TTFunk::File]
      # @param tag [String]
      def initialize(file, tag)
        @tag = tag
        super(file)
      end
    end
  end
end
