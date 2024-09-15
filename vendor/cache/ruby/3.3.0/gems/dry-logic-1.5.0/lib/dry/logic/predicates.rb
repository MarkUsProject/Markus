# frozen_string_literal: true

require "dry/core/constants"

require "bigdecimal"
require "bigdecimal/util"
require "date"

module Dry
  module Logic
    module Predicates
      include Dry::Core::Constants

      # rubocop:disable Metrics/ModuleLength
      module Methods
        def self.uuid_format(version)
          ::Regexp.new(<<~FORMAT.chomp, ::Regexp::IGNORECASE)
            \\A[0-9A-F]{8}-[0-9A-F]{4}-#{version}[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\\z
          FORMAT
        end

        UUIDv1 = uuid_format(1)

        UUIDv2 = uuid_format(2)

        UUIDv3 = uuid_format(3)

        UUIDv4 = uuid_format(4)

        UUIDv5 = uuid_format(5)

        def [](name)
          method(name)
        end

        def type?(type, input)
          input.is_a?(type)
        end

        def nil?(input)
          input.nil?
        end
        alias_method :none?, :nil?

        def key?(name, input)
          input.key?(name)
        end

        def attr?(name, input)
          input.respond_to?(name)
        end

        def empty?(input)
          case input
          when String, Array, Hash then input.empty?
          when nil then true
          else
            false
          end
        end

        def filled?(input)
          !empty?(input)
        end

        def bool?(input)
          input.is_a?(TrueClass) || input.is_a?(FalseClass)
        end

        def date?(input)
          input.is_a?(Date)
        end

        def date_time?(input)
          input.is_a?(DateTime)
        end

        def time?(input)
          input.is_a?(Time)
        end

        def number?(input)
          true if Float(input)
        rescue ArgumentError, TypeError
          false
        end

        def int?(input)
          input.is_a?(Integer)
        end

        def float?(input)
          input.is_a?(Float)
        end

        def decimal?(input)
          input.is_a?(BigDecimal)
        end

        def str?(input)
          input.is_a?(String)
        end

        def hash?(input)
          input.is_a?(Hash)
        end

        def array?(input)
          input.is_a?(Array)
        end

        def odd?(input)
          input.odd?
        end

        def even?(input)
          input.even?
        end

        def lt?(num, input)
          input < num
        end

        def gt?(num, input)
          input > num
        end

        def lteq?(num, input)
          !gt?(num, input)
        end

        def gteq?(num, input)
          !lt?(num, input)
        end

        def size?(size, input)
          case size
          when Integer then size.equal?(input.size)
          when Range, Array then size.include?(input.size)
          else
            raise ArgumentError, "+#{size}+ is not supported type for size? predicate."
          end
        end

        def min_size?(num, input)
          input.size >= num
        end

        def max_size?(num, input)
          input.size <= num
        end

        def bytesize?(size, input)
          case size
          when Integer then size.equal?(input.bytesize)
          when Range, Array then size.include?(input.bytesize)
          else
            raise ArgumentError, "+#{size}+ is not supported type for bytesize? predicate."
          end
        end

        def min_bytesize?(num, input)
          input.bytesize >= num
        end

        def max_bytesize?(num, input)
          input.bytesize <= num
        end

        def inclusion?(list, input)
          deprecated(:inclusion?, :included_in?)
          included_in?(list, input)
        end

        def exclusion?(list, input)
          deprecated(:exclusion?, :excluded_from?)
          excluded_from?(list, input)
        end

        def included_in?(list, input)
          list.include?(input)
        end

        def excluded_from?(list, input)
          !list.include?(input)
        end

        def includes?(value, input)
          if input.respond_to?(:include?)
            input.include?(value)
          else
            false
          end
        rescue TypeError
          false
        end

        def excludes?(value, input)
          !includes?(value, input)
        end

        # This overrides Object#eql? so we need to make it compatible
        def eql?(left, right = Undefined)
          return super(left) if right.equal?(Undefined)

          left.eql?(right)
        end

        def is?(left, right)
          left.equal?(right)
        end

        def not_eql?(left, right)
          !left.eql?(right)
        end

        def true?(value)
          value.equal?(true)
        end

        def false?(value)
          value.equal?(false)
        end

        def format?(regex, input)
          !input.nil? && regex.match?(input)
        end

        def case?(pattern, input)
          # rubocop:disable Style/CaseEquality
          pattern === input
          # rubocop:enable Style/CaseEquality
        end

        def uuid_v1?(input)
          format?(UUIDv1, input)
        end

        def uuid_v2?(input)
          format?(UUIDv2, input)
        end

        def uuid_v3?(input)
          format?(UUIDv3, input)
        end

        def uuid_v4?(input)
          format?(UUIDv4, input)
        end

        def uuid_v5?(input)
          format?(UUIDv5, input)
        end

        def uri?(schemes, input)
          uri_format = URI::DEFAULT_PARSER.make_regexp(schemes)
          format?(uri_format, input)
        end

        def uri_rfc3986?(input)
          format?(URI::RFC3986_Parser::RFC3986_URI, input)
        end

        # This overrides Object#respond_to? so we need to make it compatible
        def respond_to?(method, input = Undefined)
          return super if input.equal?(Undefined)

          input.respond_to?(method)
        end

        def predicate(name, &block)
          define_singleton_method(name, &block)
        end

        def deprecated(name, in_favor_of)
          Core::Deprecations.warn(
            "#{name} predicate is deprecated and will " \
            "be removed in the next major version\n" \
            "Please use #{in_favor_of} predicate instead",
            tag: "dry-logic",
            uplevel: 3
          )
        end
      end

      extend Methods

      def self.included(other)
        super
        other.extend(Methods)
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
