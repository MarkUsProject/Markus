# frozen_string_literal: true

module PDF
  module Core
    # Outline item.
    #
    # @api private
    # @see # PDF 1.7 spec, section 8.2.2 Document Outline
    class OutlineItem
      # The total number of its open descendants at all lower levels of the
      # outline hierarchy.
      # @return [Integer]
      attr_accessor :count

      # The first of this item’s immediate children in the outline hierarchy.
      # @return [Reference<PDF::Core::OutlineItem>]
      attr_accessor :first

      # The last of this item’s immediate children in the outline hierarchy.
      # @return [Reference<PDF::Core::OutlineItem>]
      attr_accessor :last

      # The next item at this outline level.
      # @return [Reference<PDF::Core::OutlineItem>]
      attr_accessor :next

      # The previous item at this outline level.
      # @return [Reference<PDF::Core::OutlineItem>]
      attr_accessor :prev

      # The parent of this item in the outline hierarchy.
      # @return [Reference<[PDF::Core::OutlineItem, PDF::Core::OutlineRoot]>]
      attr_accessor :parent

      # The text to be displayed on the screen for this item.
      # @return [String]
      attr_accessor :title

      # The destination to be displayed when this item is activated.
      # @return [String]
      # @return [Symbol]
      # @return [Array]
      # @see Destinations
      attr_accessor :dest

      # Is this item open or closed.
      # @return [Boolean]
      attr_accessor :closed

      # @param title [String]
      # @param parent [PDF::Core::OutlineRoot, PDF::Core::OutlineItem]
      # @param options [Hash]
      # @option options :closed [Boolean]
      def initialize(title, parent, options)
        @closed = options[:closed]
        @title = title
        @parent = parent
        @count = 0
      end

      # A hash representation of this outline item.
      #
      # @return [Hash]
      def to_hash
        hash = {
          Title: title,
          Parent: parent,
          Count: closed ? -count : count,
        }
        [
          { First: first }, { Last: last }, { Next: defined?(@next) && @next },
          { Prev: prev }, { Dest: dest },
        ].each do |h|
          unless h.values.first.nil?
            hash.merge!(h)
          end
        end
        hash
      end
    end
  end
end
