# frozen_string_literal: true

module TTFunk
  # Base class for different aggregate values and accumulators.
  #
  # @see TTFunk::Min
  # @see TTFunk::Max
  # @see TTFunk::Sum
  class Aggregate
    private

    def coerce(other)
      if other.respond_to?(:value_or)
        other.value_or(0)
      else
        other
      end
    end
  end
end
