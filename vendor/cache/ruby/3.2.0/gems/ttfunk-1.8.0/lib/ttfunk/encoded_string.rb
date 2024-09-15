# frozen_string_literal: true

require 'stringio'
require_relative 'placeholder'

module TTFunk
  # Risen when the final encoded string was requested but there were some
  # unresolved placeholders in it.
  class UnresolvedPlaceholderError < StandardError
  end

  # Risen when a placeholder is added to an Encoded String but it already
  # contains a placeholder with the same name.
  class DuplicatePlaceholderError < StandardError
  end

  # Encoded string takes care of placeholders in binary strings. Placeholders
  # are used when bytes need to be placed in the stream before their value is
  # known.
  #
  # @api private
  class EncodedString
    # @yieldparam [self]
    def initialize
      yield(self) if block_given?
    end

    # Append to string.
    #
    # @param obj [String, Placeholder, EncodedString]
    # @return [self]
    def <<(obj)
      case obj
      when String
        io << obj
      when Placeholder
        add_placeholder(obj)
        io << ("\0" * obj.length)
      when self.class
        # adjust placeholders to be relative to the entire encoded string
        obj.placeholders.each_pair do |_, placeholder|
          add_placeholder(placeholder.dup, placeholder.position + io.length)
        end

        io << obj.unresolved_string
      end

      self
    end

    # Append multiple objects.
    #
    # @param objs [Array<String, Placeholder, EncodedString>]
    # @return [self]
    def concat(*objs)
      objs.each do |obj|
        self << obj
      end
      self
    end

    # Append padding to align string to the specified word width.
    #
    # @param width [Integer]
    # @return [self]
    def align!(width = 4)
      if (length % width).positive?
        self << ("\0" * (width - (length % width)))
      end

      self
    end

    # Length of this string.
    #
    # @return [Integer]
    def length
      io.length
    end

    # Raw string.
    #
    # @return [String]
    # @raise [UnresolvedPlaceholderError] if there are any unresolved
    #   placeholders left.
    def string
      unless placeholders.empty?
        raise UnresolvedPlaceholderError,
          "string contains #{placeholders.size} unresolved placeholder(s)"
      end

      io.string
    end

    # Raw bytes.
    #
    # @return [Array<Integer>]
    # @raise [UnresolvedPlaceholderError] if there are any unresolved
    #   placeholders left.
    def bytes
      string.bytes
    end

    # Unresolved raw string.
    #
    # @return [String]
    def unresolved_string
      io.string
    end

    # Resolve placeholder.
    #
    # @param name [Symbol]
    # @param value [String]
    # @return [void]
    def resolve_placeholder(name, value)
      last_pos = io.pos

      if (placeholder = placeholders[name])
        io.seek(placeholder.position)
        io.write(value[0..placeholder.length])
        placeholders.delete(name)
      end
    ensure
      io.seek(last_pos)
    end

    # Plaholders
    #
    # @return [Hash{Symbol => Plaholder}]
    def placeholders
      @placeholders ||= {}
    end

    private

    def add_placeholder(new_placeholder, pos = io.pos)
      if placeholders.include?(new_placeholder.name)
        raise DuplicatePlaceholderError,
          "placeholder #{new_placeholder.name} already exists"
      end

      new_placeholder.position = pos
      placeholders[new_placeholder.name] = new_placeholder
    end

    def io
      @io ||= StringIO.new(''.b).binmode
    end
  end
end
