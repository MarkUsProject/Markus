# frozen_string_literal: true

module TTFunk
  # Maximum aggregate. Its value can only become greater.
  class Max < Aggregate
    # Value
    #
    # @return [Comparable, nil]
    attr_reader :value

    # @param init_value [Comparable] initial value
    def initialize(init_value = nil)
      super()
      @value = init_value
    end

    # Push a value. It will become the new value if it's greater than the
    # current value (or if there was no value).
    #
    # @param new_value [Comparable]
    # @return [void]
    def <<(new_value)
      new_value = coerce(new_value)

      if value.nil? || new_value > value
        @value = new_value
      end
    end

    # Get the stored value or default.
    #
    # @param default [any]
    # @return [any]
    def value_or(default)
      return default if value.nil?

      value
    end
  end
end
