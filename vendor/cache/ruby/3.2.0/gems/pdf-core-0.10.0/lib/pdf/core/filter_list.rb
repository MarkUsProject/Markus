# frozen_string_literal: true

module PDF
  module Core
    # A representation of a list of filters applied to a stream.
    class FilterList
      # An exception one can expect when adding something to filter list that
      # can not be interpreted as a filter.
      class NotFilter < StandardError
        # Generic default error message
        DEFAULT_MESSAGE = 'Can not interpret input as a filter'

        # Error message template with more details
        MESSAGE_WITH_FILTER = 'Can not interpret input as a filter: %<filter>s'

        def initialize(message = DEFAULT_MESSAGE, filter: nil)
          if filter
            super(format(MESSAGE_WITH_FILTER, filter: filter))
          else
            super(message)
          end
        end
      end

      def initialize
        @list = []
      end

      # Appends a filter to the list
      #
      # @param filter [Symbol, Hash] a filter to append
      # @return [self]
      # @raise [NotFilter]
      def <<(filter)
        case filter
        when Symbol
          @list << [filter, nil]
        when ::Hash
          filter.each do |name, params|
            @list << [name, params]
          end
        else
          raise NotFilter.new(filter: filter)
        end

        self
      end

      # A normalized representation of the filter list
      #
      # @return [Array<Array<(Symbol, [Hash, nil])>>]
      def normalized
        @list
      end
      alias to_a normalized

      # Names of filters in the list
      #
      # @return [Array<Symbol>]
      def names
        @list.map do |(name, _)|
          name
        end
      end

      # Parameters of filters
      #
      # @return [Array<[Hash, nil]>]
      def decode_params
        @list.map do |(_, params)|
          params
        end
      end

      # @return [String]
      def inspect
        @list.inspect
      end

      # Iterates over filters
      #
      # @yield [(name, decode_params)] an array of filter name and decode
      #   parameters
      # @yieldparam name [Symbol] filter name
      # @yieldparam decode_params [Hash, nil] decode params
      # @return [Array<Array<(Symbol, [Hash, nil])>>] normalized filter list
      def each(&block)
        @list.each(&block)
      end
    end
  end
end
