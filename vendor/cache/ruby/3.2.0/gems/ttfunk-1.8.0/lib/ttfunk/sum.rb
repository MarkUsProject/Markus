# frozen_string_literal: true

module TTFunk
  # Sum aggreaget. Is sums all pushed values.
  class Sum < Aggregate
    # Value
    #
    # @return [#+]
    attr_reader :value

    # @param init_value [#+] initial value
    def initialize(init_value = 0)
      super()
      @value = init_value
    end

    # Push a value. It will be added to the current value.
    #
    # @param operand [any]
    # @return [void]
    def <<(operand)
      @value += coerce(operand)
    end

    # Get the stored value or default.
    #
    # @param _default [any] Unused. Here for API compatibility.
    # @return [any]
    def value_or(_default)
      # value should always be non-nil
      value
    end
  end
end
