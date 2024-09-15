# frozen_string_literal: true

module TTFunk
  # Bitfield represents a series of bits that can individually be toggled.
  class BitField
    # Serialized value.
    # @return [Integer]
    attr_reader :value

    # @param value [Integer] initial value
    def initialize(value = 0)
      @value = value
    end

    # Set bit on.
    #
    # @param pos [Integer] bit position
    # @return [void]
    def on(pos)
      @value |= 2**pos
    end

    # If bit on?
    #
    # @param pos [Integer]
    # @return [Boolean]
    def on?(pos)
      (value & (2**pos)).positive?
    end

    # Set bit off.
    #
    # @param pos [Integer]
    # @return [void]
    def off(pos)
      @value &= (2**Math.log2(value).ceil) - (2**pos) - 1
    end

    # Is bit off?
    #
    # @param pos [Integer]
    # @return [Boolean]
    def off?(pos)
      !on?(pos)
    end

    # Get a duplicate of this bit field.
    #
    # @return [BitField]
    def dup
      self.class.new(value)
    end
  end
end
