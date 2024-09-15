# frozen_string_literal: true

module PDF
  module Core
    # Document Outline root.
    #
    # @api private
    # @see # PDF 1.7 spec, section 8.2.2 Document Outline
    class OutlineRoot
      # The total number of open items at all levels of the outline.
      # @return [Integer]
      attr_accessor :count

      # The first top-level item in the outline.
      # @return [Reference]
      attr_accessor :first

      # The last top-level item in the outline.
      # @return [Reference]
      attr_accessor :last

      def initialize
        @count = 0
      end

      # Hash representation of the outline root
      # @return [Hash]
      def to_hash
        { Type: :Outlines, Count: count, First: first, Last: last }
      end
    end
  end
end
