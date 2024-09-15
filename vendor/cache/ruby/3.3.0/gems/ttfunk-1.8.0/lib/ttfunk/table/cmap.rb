# frozen_string_literal: true

module TTFunk
  class Table
    # Character to Glyph Index Mapping (`cmap`) table.
    class Cmap < Table
      # Table version.
      # @return [Integer]
      attr_reader :version

      # Encoding tables.
      # @return [Array<TTFunk::Table::Cmap::Subtable>]
      attr_reader :tables

      # Encode table.
      #
      # @param charmap [Hash{Integer => Integer}]
      # @param encoding [Symbol]
      # @return [Hash]
      #   * `:charmap` (<tt>Hash{Integer => Hash}</tt>) keys are the characrers in
      #     `charset`, values are hashes:
      #     * `:old` (<tt>Integer</tt>) - glyph ID in the original font.
      #     * `:new` (<tt>Integer</tt>) - glyph ID in the subset font.
      #     that maps the characters in charmap to a
      #   * `:table` (<tt>String</tt>) - serialized table.
      #   * `:max_glyph_id` (<tt>Integer</tt>) - maximum glyph ID in the new font.
      def self.encode(charmap, encoding)
        result = Cmap::Subtable.encode(charmap, encoding)

        # pack 'version' and 'table-count'
        result[:table] = [0, 1, result.delete(:subtable)].pack('nnA*')
        result
      end

      # Get Unicode encoding records.
      #
      # @return [Array<TTFunk::Table::Cmap::Subtable>]
      def unicode
        # Because most callers just call .first on the result, put tables with
        # highest-number format first. Unsupported formats will be ignored.
        @unicode ||=
          @tables
            .select { |table| table.unicode? && table.supported? }
            .sort { |a, b| b.format <=> a.format }
      end

      private

      def parse!
        @version, table_count = read(4, 'nn')
        @tables =
          Array.new(table_count) do
            Cmap::Subtable.new(file, offset)
          end
      end
    end
  end
end

require_relative 'cmap/subtable'
