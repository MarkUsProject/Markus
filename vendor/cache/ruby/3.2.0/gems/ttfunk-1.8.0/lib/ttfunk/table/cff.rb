# frozen_string_literal: true

module TTFunk
  class Table
    # Compact Font Format (`CFF `) table
    class Cff < TTFunk::Table
      autoload :Charset, 'ttfunk/table/cff/charset'
      autoload :Charsets, 'ttfunk/table/cff/charsets'
      autoload :Charstring, 'ttfunk/table/cff/charstring'
      autoload :CharstringsIndex, 'ttfunk/table/cff/charstrings_index'
      autoload :Dict, 'ttfunk/table/cff/dict'
      autoload :Encoding, 'ttfunk/table/cff/encoding'
      autoload :Encodings, 'ttfunk/table/cff/encodings'
      autoload :FdSelector, 'ttfunk/table/cff/fd_selector'
      autoload :FontDict, 'ttfunk/table/cff/font_dict'
      autoload :FontIndex, 'ttfunk/table/cff/font_index'
      autoload :Header, 'ttfunk/table/cff/header'
      autoload :Index, 'ttfunk/table/cff/index'
      autoload :OneBasedIndex, 'ttfunk/table/cff/one_based_index'
      autoload :Path, 'ttfunk/table/cff/path'
      autoload :PrivateDict, 'ttfunk/table/cff/private_dict'
      autoload :SubrIndex, 'ttfunk/table/cff/subr_index'
      autoload :TopDict, 'ttfunk/table/cff/top_dict'
      autoload :TopIndex, 'ttfunk/table/cff/top_index'

      # Table tag. The extra space is important.
      TAG = 'CFF '

      # Table header.
      # @return [TTFunk::Table::Cff::Header]
      attr_reader :header

      # Name index.
      # @return [TTFunk::Table::Cff::Index]
      attr_reader :name_index

      # Top dict index.
      # @return [TTFunk::Table::Cff::TopIndex]
      attr_reader :top_index

      # Strings index.
      # @return [TTFunk::Table::Cff::OneBasedIndex]
      attr_reader :string_index

      # Global subroutine index.
      # @return [TTFunk::Table::Cff::SubrIndex]
      attr_reader :global_subr_index

      # Table tag.
      # @return [String]
      def tag
        TAG
      end

      # Encode table.
      #
      # @param subset [TTFunk::Subset::MacRoman, TTFunk::Subset::Windows1252,
      #   TTFunk::Subset::Unicode, TTFunk::Subset::Unicode8Bit]
      # @return [TTFunk::EncodedString]
      def encode(subset)
        # Make sure TopDict has an entry for encoding so it could be properly replaced
        top_index[0][TopDict::OPERATORS[:encoding]] = 0

        EncodedString.new do |result|
          result.concat(
            header.encode,
            name_index.encode,
            top_index.encode,
            string_index.encode,
            global_subr_index.encode,
          )

          charmap = subset.new_cmap_table[:charmap]
          top_index[0].finalize(result, charmap)
        end
      end

      private

      def parse!
        @header = Header.new(file, offset)
        @name_index = Index.new(file, @header.table_offset + @header.length)
        @top_index = TopIndex.new(file, @name_index.table_offset + @name_index.length)
        @string_index = OneBasedIndex.new(file, @top_index.table_offset + @top_index.length)
        @global_subr_index = SubrIndex.new(file, @string_index.table_offset + @string_index.length)
      end
    end
  end
end
