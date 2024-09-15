# frozen_string_literal: true

# prawn/core/stream.rb : Implements Stream objects
#
# Copyright February 2013, Alexander Mankuta.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    # PDF Stream object
    class Stream
      # Stream filters
      # @return [PDF::Core::FilterList]
      attr_reader :filters

      # @param io [String] must be mutable
      def initialize(io = nil)
        @filtered_stream = ''
        @stream = io
        @filters = FilterList.new
      end

      # Append data to stream.
      #
      # @param io [String]
      # @return [self]
      def <<(io)
        (@stream ||= +'') << io
        @filtered_stream = nil
        self
      end

      # Set up stream to be compressed when serialized.
      #
      # @return [void]
      def compress!
        unless @filters.names.include?(:FlateDecode)
          @filtered_stream = nil
          @filters << :FlateDecode
        end
      end

      # Is this stream compressed?
      #
      # @return [Boolean]
      def compressed?
        @filters.names.include?(:FlateDecode)
      end

      # Is there any data in this stream?
      #
      # @return [Boolean]
      def empty?
        @stream.nil?
      end

      # Stream data with filters applied.
      #
      # @return [Stream]
      def filtered_stream
        if @stream
          if @filtered_stream.nil?
            @filtered_stream = @stream.dup

            @filters.each do |(filter_name, params)|
              filter = PDF::Core::Filters.const_get(filter_name)
              if filter
                @filtered_stream = filter.encode(@filtered_stream, params)
              end
            end
          end

          @filtered_stream
        end
      end

      # Size of data in the stream
      #
      # @return [Integer]
      def length
        @stream.length
      end

      # Serialized stream data
      #
      # @return [String]
      def object
        if filtered_stream
          "stream\n#{filtered_stream}\nendstream\n"
        else
          ''
        end
      end

      # Stream dictionary
      #
      # @return [Hash]
      def data
        if @stream
          filter_names = @filters.names
          filter_params = @filters.decode_params

          d = {
            Length: filtered_stream.length,
          }
          if filter_names.any?
            d[:Filter] = filter_names
          end
          if filter_params.any? { |f| !f.nil? }
            d[:DecodeParms] = filter_params
          end

          d
        else
          {}
        end
      end

      # String representation of the stream for debugging purposes.
      #
      # @return [String]
      def inspect
        format(
          '#<%<class>s:0x%<object_id>014x @stream=%<stream>s, @filters=%<filters>s>',
          class: self.class.name,
          object_id: object_id,
          stream: @stream.inspect,
          filters: @filters.inspect,
        )
      end
    end
  end
end
