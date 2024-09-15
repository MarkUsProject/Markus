# frozen_string_literal: true

require 'zlib'

module PDF
  module Core
    # Stream filters
    module Filters
      # zlib/deflate compression
      module FlateDecode
        # Encode stream data
        #
        # @param stream [String] stream data
        # @param _params [nil] unused, here for API compatibility
        # @return [String]
        def self.encode(stream, _params = nil)
          Zlib::Deflate.deflate(stream)
        end

        # Decode stream data
        #
        # @param stream [String] stream data
        # @param _params [nil] unused, here for API compatibility
        # @return [String]
        def self.decode(stream, _params = nil)
          Zlib::Inflate.inflate(stream)
        end
      end

      # Data encoding using DCT (discrete cosine transform) technique based on
      # the JPEG standard.
      #
      # Pass through stub.
      module DCTDecode
        # Encode stream data
        #
        # @param stream [String] stream data
        # @param _params [nil] unused, here for API compatibility
        # @return [String]
        def self.encode(stream, _params = nil)
          stream
        end

        # Decode stream data
        #
        # @param stream [String] stream data
        # @param _params [nil] unused, here for API compatibility
        # @return [String]
        def self.decode(stream, _params = nil)
          stream
        end
      end
    end
  end
end
