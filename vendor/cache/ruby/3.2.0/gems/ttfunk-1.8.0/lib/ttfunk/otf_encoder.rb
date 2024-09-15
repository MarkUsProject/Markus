# frozen_string_literal: true

module TTFunk
  # Encodes a CFF-based OpenType font subset to its binary representation.
  class OTFEncoder < TTFEncoder
    # Optimal table order according to OpenType specification.
    OPTIMAL_TABLE_ORDER = ['head', 'hhea', 'maxp', 'OS/2', 'name', 'cmap', 'post', 'CFF '].freeze

    private

    # CFF fonts don't maintain a glyf table, all glyph information is stored
    # in the charstrings index. Return an empty hash here to indicate a glyf
    # table should not be encoded.
    def glyf_table
      @glyf_table ||= {}
    end

    # Since CFF fonts don't maintain a glyf table, they also don't maintain
    # a loca table. Return an empty hash here to indicate a loca table
    # shouldn't be encoded.
    def loca_table
      @loca_table ||= {}
    end

    def base_table
      @base_table ||= TTFunk::Table::Simple.new(original, 'BASE').raw
    end

    def cff_table
      @cff_table ||= original.cff.encode(subset)
    end

    def vorg_table
      @vorg_table ||= TTFunk::Table::Vorg.encode(original.vertical_origins)
    end

    def tables
      @tables ||= super.merge(
        'BASE' => base_table,
        'VORG' => vorg_table,
        'CFF ' => cff_table,
      ).compact
    end

    def optimal_table_order
      # DSIG is always last
      OPTIMAL_TABLE_ORDER +
        (tables.keys - ['DSIG'] - OPTIMAL_TABLE_ORDER) +
        ['DSIG']
    end
  end
end
