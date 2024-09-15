# frozen_string_literal: true

require 'set'

require_relative 'base'

module TTFunk
  module Subset
    # A subset that uses standard code page encoding.
    class CodePage < Base
      class << self
        # Get a mapping from an encoding to Unicode
        #
        # @param encoding [Encoding, String, Symbol]
        # @return [Hash{Integer => Integer}]
        def unicode_mapping_for(encoding)
          mapping_cache[encoding] ||=
            (0..255).each_with_object({}) do |c, ret|
              codepoint =
                c.chr(encoding)
                  .encode(Encoding::UTF_8, undef: :replace, replace: '')
                  .codepoints
                  .first
              ret[c] = codepoint if codepoint
            end
        end

        private

        def mapping_cache
          @mapping_cache ||= {}
        end
      end

      # Code page used in this subset.
      # This is used for proper `OS/2` table encoding.
      # @return [Integer]
      attr_reader :code_page

      # Encoding used in this subset.
      # @return [Encoding, String, Symbol]
      attr_reader :encoding

      # @param original [TTFunk::File]
      # @param code_page [Integer]
      # @param encoding [Encoding, String, Symbol]
      def initialize(original, code_page, encoding)
        super(original)
        @code_page = code_page
        @encoding = encoding
        @subset = Array.new(256)
        @from_unicode_cache = {}
        use(space_char_code)
      end

      # Get a mapping from this subset to Unicode.
      #
      # @return [Hash]
      def to_unicode_map
        self.class.unicode_mapping_for(encoding)
          .select { |codepoint, _unicode| @subset[codepoint] }
      end

      # Add a character to subset.
      #
      # @param character [Integer] Unicode codepoint
      # @return [void]
      def use(character)
        @subset[from_unicode(character)] = character
      end

      # Can this subset include the character? This depends on the encoding used
      # in this subset.
      #
      # @param character [Integer] Unicode codepoint
      # @return [Boolean]
      def covers?(character)
        !from_unicode(character).nil?
      end

      # Does this subset actually has the character?
      #
      # @param character [Integer] Unicode codepoint
      # @return [Boolean]
      def includes?(character)
        code = from_unicode(character)
        code && @subset[code]
      end

      # Get character code for Unicode codepoint.
      #
      # @param character [Integer] Unicode codepoint
      # @return [Integer, nil]
      def from_unicode(character)
        @from_unicode_cache[character] ||= (+'' << character).encode!(encoding).ord
      rescue Encoding::UndefinedConversionError
        nil
      end

      # Get `cmap` table for this subset.
      #
      # @return [TTFunk::Table::Cmap]
      def new_cmap_table
        @new_cmap_table ||=
          begin
            mapping = {}

            @subset.each_with_index do |unicode, roman|
              mapping[roman] = unicode_cmap[unicode]
            end

            TTFunk::Table::Cmap.encode(mapping, :mac_roman)
          end
      end

      # Get the list of Glyph IDs from the original font that are in this
      # subset.
      #
      # @return [Array<Integer>]
      def original_glyph_ids
        ([0] + @subset.map { |unicode| unicode && unicode_cmap[unicode] })
          .compact.uniq.sort
      end

      # Get a chacter code for Space in this subset
      #
      # @return [Integer, nil]
      def space_char_code
        @space_char_code ||= from_unicode(Unicode::SPACE_CHAR)
      end
    end
  end
end
