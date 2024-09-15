# frozen_string_literal: true

require 'set'
require_relative 'base'

module TTFunk
  module Subset
    # Unicode-based subset.
    class Unicode < Base
      # Space character code
      SPACE_CHAR = 0x20

      # @param original [TTFunk::File]
      def initialize(original)
        super
        @subset = Set.new
        use(SPACE_CHAR)
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
        @subset.each_with_object({}) { |code, map| map[code] = code }
      end

      # Add a character to subset.
      #
      # @param character [Integer] Unicode codepoint
      # @return [void]
      def use(character)
        @subset << character
      end

      # Can this subset include the character?
      #
      # @param _character [Integer] Unicode codepoint
      # @return [true]
      def covers?(_character)
        true
      end

      # Does this subset actually has the character?
      #
      # @param character [Integer] Unicode codepoint
      # @return [Boolean]
      def includes?(character)
        @subset.include?(character)
      end

      # Get character code for Unicode codepoint.
      #
      # @param character [Integer] Unicode codepoint
      # @return [Integer]
      def from_unicode(character)
        character
      end

      # Get `cmap` table for this subset.
      #
      # @return [TTFunk::Table::Cmap]
      def new_cmap_table
        @new_cmap_table ||=
          begin
            mapping =
              @subset.each_with_object({}) do |code, map|
                map[code] = unicode_cmap[code]
              end

            TTFunk::Table::Cmap.encode(mapping, :unicode)
          end
      end

      # Get the list of Glyph IDs from the original font that are in this
      # subset.
      #
      # @return [Array<Integer>]
      def original_glyph_ids
        ([0] + @subset.map { |code| unicode_cmap[code] }).uniq.sort
      end
    end
  end
end
