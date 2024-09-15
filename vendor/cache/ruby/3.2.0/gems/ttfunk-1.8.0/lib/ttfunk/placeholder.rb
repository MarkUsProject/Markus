# frozen_string_literal: true

module TTFunk
  # Encoded String placeholder.
  #
  # @api private
  class Placeholder
    # Placeholder position in the cintaining Encoded String
    # @return [Integer]
    attr_accessor :position

    # Planceholder name
    # @return [Symbol]
    attr_reader :name

    # Length of the placeholder
    # @return [Integer]
    attr_reader :length

    # @param name [Symbol]
    # @param length [Integer]
    def initialize(name, length: 1)
      @name = name
      @length = length
    end
  end
end
