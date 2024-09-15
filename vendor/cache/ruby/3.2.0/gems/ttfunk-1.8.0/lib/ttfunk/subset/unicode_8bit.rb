# frozen_string_literal: true

require 'set'
require_relative 'base'

module TTFunk
  module Subset
    # An 8-bit Unicode-based subset. It can include any Unicode character but
    # limits number of characters so that the could be encoded by a single byte.
    class Unicode8Bit < Base
      # @param original [TTFunk::File]
      def initialize(original)
        super
        @subset = { 0x20 => 0x20 }
        @unicodes = { 0x20 => 0x20 }
        @next = 0x21 # apparently, PDF's don't like to use chars between 0-31
      end

      # Is this a Unicode-based subset?
      #
      # @return [true]
      def unicode?
        true
      end

      # Get a mapping from this subset to Unicode.
      #
      # @return [Hash{Integer => Integer}]
      def to_unicode_map
        @subset.dup
      end

      # Add a character to subset.
      #
      # @param character [Integer] Unicode codepoint
      # @return [void]
      def use(character)
        unless @unicodes.key?(character)
          @subset[@next] = character
          @unicodes[character] = @next
          @next += 1
        end
      end

      # Can this subset include the character?
      #
      # @param character [Integer] Unicode codepoint
      # @return [Boolean]
      def covers?(character)
        @unicodes.key?(character) || @next < 256
      end

      # Does this subset actually has the character?
      #
      # @param character [Integer] Unicode codepoint
      # @return [Boolean]
      def includes?(character)
        @unicodes.key?(character)
      end

      # Get character code for Unicode codepoint.
      #
      # @param character [Integer] Unicode codepoint
      # @return [Integer]
      def from_unicode(character)
        @unicodes[character]
      end

      # Get `cmap` table for this subset.
      #
      # @return [TTFunk::Table::Cmap]
      def new_cmap_table
        @new_cmap_table ||=
          begin
            mapping =
              @subset.each_with_object({}) do |(code, unicode), map|
                map[code] = unicode_cmap[unicode]
                map
              end

            # since we're mapping a subset of the unicode glyphs into an
            # arbitrary 256-character space, the actual encoding we're
            # using is irrelevant. We choose MacRoman because it's a 256-character
            # encoding that happens to be well-supported in both TTF and
            # PDF formats.
            TTFunk::Table::Cmap.encode(mapping, :mac_roman)
          end
      end

      # Get the list of Glyph IDs from the original font that are in this
      # subset.
      #
      # @return [Array<Integer>]
      def original_glyph_ids
        ([0] + @unicodes.keys.map { |unicode| unicode_cmap[unicode] }).uniq.sort
      end
    end
  end
end
