# frozen_string_literal: true

module Dry
  module Types
    # Common API for types
    #
    # @api public
    module Decorator
      include Options

      # @return [Type]
      attr_reader :type

      # @param [Type] type
      def initialize(type, *, **)
        super
        @type = type
      end

      # @param [Object] input
      # @param [#call, nil] block
      #
      # @return [Result,Logic::Result]
      # @return [Object] if block given and try fails
      #
      # @api public
      def try(input, &block)
        type.try(input, &block)
      end

      # @return [Boolean]
      #
      # @api public
      def default?
        type.default?
      end

      # @return [Boolean]
      #
      # @api public
      def constrained?
        type.constrained?
      end

      # @param [Symbol] meth
      # @param [Boolean] include_private
      #
      # @return [Boolean]
      #
      # @api public
      def respond_to_missing?(meth, include_private = false)
        super || type.respond_to?(meth)
      end

      # Wrap the type with a proc
      #
      # @return [Proc]
      #
      # @api public
      def to_proc
        proc { |value| self.(value) }
      end

      private

      # @param [Object] response
      #
      # @return [Boolean]
      #
      # @api private
      def decorate?(response)
        response.is_a?(type.class)
      end

      # Delegates missing methods to {#type}
      #
      # @param [Symbol] meth
      # @param [Array] args
      # @param [#call, nil] block
      #
      # @api private
      def method_missing(meth, *args, &block)
        if type.respond_to?(meth)
          response = type.public_send(meth, *args, &block)

          if decorate?(response)
            __new__(response)
          else
            response
          end
        else
          super
        end
      end
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

      # Replace underlying type
      #
      # @api private
      def __new__(type)
        self.class.new(type, *@__args__.drop(1), **@options)
      end
    end
  end
end
