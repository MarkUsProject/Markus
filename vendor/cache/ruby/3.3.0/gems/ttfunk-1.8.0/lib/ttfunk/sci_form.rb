# frozen_string_literal: true

module TTFunk
  # Scientific number representation
  class SciForm
    # Significand
    # @return [Float, Integer]
    attr_reader :significand

    # Exponent
    # @return [Float, Integer]
    attr_reader :exponent

    # @param significand [Float, Integer]
    # @param exponent [Float, Integer]
    def initialize(significand, exponent = 0)
      @significand = significand
      @exponent = exponent
    end

    # Convert to Float.
    #
    # @return [Float]
    def to_f
      significand * (10**exponent)
    end

    # Check equality to another number.
    #
    # @param other [Float, SciForm]
    # @return [Boolean]
    def ==(other)
      case other
      when Float
        other == to_f # rubocop: disable Lint/FloatComparison
      when self.class
        other.significand == significand &&
          other.exponent == exponent
      else
        false
      end
    end

    alias eql? ==
  end
end
