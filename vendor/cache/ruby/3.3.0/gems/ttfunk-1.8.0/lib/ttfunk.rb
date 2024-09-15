# frozen_string_literal: true

require 'stringio'
require 'pathname'

require_relative 'ttfunk/aggregate'
require_relative 'ttfunk/directory'
require_relative 'ttfunk/resource_file'
require_relative 'ttfunk/collection'
require_relative 'ttfunk/ttf_encoder'
require_relative 'ttfunk/encoded_string'
require_relative 'ttfunk/placeholder'
require_relative 'ttfunk/otf_encoder'
require_relative 'ttfunk/sci_form'
require_relative 'ttfunk/bit_field'
require_relative 'ttfunk/bin_utils'
require_relative 'ttfunk/sub_table'
require_relative 'ttfunk/min'
require_relative 'ttfunk/max'
require_relative 'ttfunk/sum'
require_relative 'ttfunk/one_based_array'

# TTFunk is a TrueType and OpenType font library written in pure ruby. It
# supports both parsing and encoding of fonts. Also provides limited font
# subsetting.
#
# It supports a veriety of SFNT-based formats:
# * TrueType fonts (ttf)
# * OpenType fonts (otf), with both TrueType and CFF glyph outlines
# * DFont resources (dfont)
# * TrueType Collections (ttc)
#
# While not all TrueType and OpenType tables are implemented the most common
# ones are.
module TTFunk
  # TTFunk-specific exceptions
  class Error < StandardError; end

  # File represents an individual font. It can represents both TrueType and
  # OpenType fonts.
  class File
    # Raw content of the font.
    # @return [String]
    attr_reader :contents

    # Font tables directory.
    # @return [TTFunk::Directory]
    attr_reader :directory

    # Open font file
    #
    # @overload open(io)
    #   @param io [IO] IO to read font content from. IO position and binmode
    #     might change.
    #   @return [TTFunk::File]
    # @overload open(path)
    #   @param path [String, Pathname] Path to file to read the font from.
    #   @return [TTFunk::File]
    def self.open(io_or_path)
      new(verify_and_read(io_or_path))
    end

    # Load a font from a resource file.
    #
    # @param file [String, Pathname] Path to the resource file.
    # @param which [Integer, String] index or name of the font to load
    # @return [TTFunk::File]]
    def self.from_dfont(file, which = 0)
      new(ResourceFile.open(file) { |dfont| dfont['sfnt', which] })
    end

    # Load a font from a TrueType collection.
    #
    # @overload from_ttc(io, which = 0)
    #   @param file [IO] IO to read the collection from.
    #   @param which [Integer] index of the font to load
    #   @return [TTFunk::File]
    # @overload from_ttc(file_path, which = 0)
    #   @param file_path [String, Pathname] Path to the resource file.
    #   @param which [Integer] index of the font to load
    #   @return [TTFunk::File]
    def self.from_ttc(file, which = 0)
      Collection.open(file) { |ttc| ttc[which] }
    end

    # Turn a path or IO into an IO convenient for TTFunk. The resulting IO is
    # going to be in bin mode and its position set to the beginning.
    #
    # @overload verify_and_open(io)
    #   @param io [IO] IO to prepare. Its position and binmode might
    #     change.
    #   @return [io]
    # @overload verify_and_open(path)
    #   @param path [String, Pathname] path of the file to turn into an IO.
    #   @return [IO] newly opened IO for the path
    # @deprecated This method might retain open files for longer than necessary.
    # @see .verify_and_read
    def self.verify_and_open(io_or_path)
      # File or IO
      if io_or_path.respond_to?(:rewind)
        io = io_or_path
        # Rewind if the object we're passed is an IO, so that multiple embeds of
        # the same IO object will work
        io.rewind
        # read the file as binary so the size is calculated correctly
        # guard binmode because some objects acting io-like don't implement it
        io.binmode if io.respond_to?(:binmode)
        return io
      end
      # String or Pathname
      io_or_path = Pathname.new(io_or_path)
      raise ArgumentError, "#{io_or_path} not found" unless io_or_path.file?

      io_or_path.open('rb')
    end

    # Read contents of a path or IO.
    #
    # @overload verify_and_read(io)
    #   @param io [IO] IO to read from. Its position and binmode might
    #     change. IO is read from the beginning regardless of its initial
    #     position.
    #   @return [String]
    # @overload verify_and_read(path)
    #   @param path [String, Pathname] path of the file to read.
    #   @return [String]
    def self.verify_and_read(io_or_path)
      # File or IO
      if io_or_path.respond_to?(:rewind)
        io = io_or_path
        # Rewind if the object we're passed is an IO, so that multiple embeds of
        # the same IO object will work
        io.rewind
        # read the file as binary so the size is calculated correctly
        # guard binmode because some objects acting io-like don't implement it
        io.binmode if io.respond_to?(:binmode)
        return io.read
      end
      # String or Pathname
      io_or_path = Pathname.new(io_or_path)
      raise ArgumentError, "#{io_or_path} not found" unless io_or_path.file?

      io_or_path.binread
    end

    # @param contents [String] binary string containg the font data
    # @param offset [Integer] offset at which the font data starts
    def initialize(contents, offset = 0)
      @contents = StringIO.new(contents)
      @directory = Directory.new(@contents, offset)
    end

    # Glyphs ascent as defined for in the font.
    #
    # @return [Integer]
    def ascent
      @ascent ||= (os2.exists? && os2.ascent && os2.ascent.nonzero?) ||
        horizontal_header.ascent
    end

    # Glyphs descent as defined in the font.
    #
    # @return [Integer]
    def descent
      @descent ||= (os2.exists? && os2.descent && os2.descent.nonzero?) ||
        horizontal_header.descent
    end

    # Line gap as defined in the font.
    #
    # @return [Integer]
    def line_gap
      @line_gap ||= (os2.exists? && os2.line_gap && os2.line_gap.nonzero?) ||
        horizontal_header.line_gap
    end

    # Glyps bounding box as defined in the font.
    #
    # @return [Array(Integer, Integer, Integer, Integer)]
    def bbox
      [header.x_min, header.y_min, header.x_max, header.y_max]
    end

    # Font directory entry for the table with the provided tag.
    #
    # @param tag [String] table tab
    # @return [Hash, nil]
    def directory_info(tag)
      directory.tables[tag.to_s]
    end

    # Font Header (`head`) table
    #
    # @return [TTFunk::Table::Head, nil]
    def header
      @header ||= TTFunk::Table::Head.new(self)
    end

    # Character to Glyph Index Mapping (`cmap`) table
    #
    # @return [TTFunk::Tbale::Cmap, nil]
    def cmap
      @cmap ||= TTFunk::Table::Cmap.new(self)
    end

    # Horizontal Header (`hhea`) table
    #
    # @return [TTFunk::Table::Hhea, nil]
    def horizontal_header
      @horizontal_header ||= TTFunk::Table::Hhea.new(self)
    end

    # Horizontal Metrics (`hmtx`) table
    #
    # @return [TTFunk::Table::Hmtx, nil]
    def horizontal_metrics
      @horizontal_metrics ||= TTFunk::Table::Hmtx.new(self)
    end

    # Maximum Profile (`maxp`) table
    #
    # @return [TTFunk::Table::Maxp, nil]
    def maximum_profile
      @maximum_profile ||= TTFunk::Table::Maxp.new(self)
    end

    # Kerning (`kern`) table
    #
    # @return [TTFunk::Table::Kern, nil]
    def kerning
      @kerning ||= TTFunk::Table::Kern.new(self)
    end

    # Naming (`name`) table
    #
    # @return [TTFunk::Table::Name, nil]
    def name
      @name ||= TTFunk::Table::Name.new(self)
    end

    # OS/2 and Windows Metrics (`OS/2`) table
    #
    # @return [TTFunk::Table:OS2, nil]
    def os2
      @os2 ||= TTFunk::Table::OS2.new(self)
    end

    # PostScript (`post`) table
    #
    # @return [TTFunk::Table::Post, nil]
    def postscript
      @postscript ||= TTFunk::Table::Post.new(self)
    end

    # Index to Location (`loca`) table
    #
    # @return [TTFunk::Table::Loca, nil]
    def glyph_locations
      @glyph_locations ||= TTFunk::Table::Loca.new(self)
    end

    # Glyph Data (`glyf`) table
    #
    # @return [TTFunk::Table::Glyf, nil]
    def glyph_outlines
      @glyph_outlines ||= TTFunk::Table::Glyf.new(self)
    end

    # Standard Bitmap Graphics (`sbix`) table
    #
    # @return [TTFunk::Table::Sbix, nil]
    def sbix
      @sbix ||= TTFunk::Table::Sbix.new(self)
    end

    # Compact Font Format (`CFF `) table
    #
    # @return [Table::Table::Cff, nil]
    def cff
      @cff ||= TTFunk::Table::Cff.new(self)
    end

    # Vertical Origin (`VORG`) table
    #
    # @return [TTFunk::Table::Vorg, nil]
    def vertical_origins
      @vertical_origins ||=
        if directory.tables.include?(TTFunk::Table::Vorg::TAG)
          TTFunk::Table::Vorg.new(self)
        end
    end

    # Digital Signature (`DSIG`) table
    #
    # @return [TTFunk::Table::Dsig, nil]
    def digital_signature
      @digital_signature ||=
        if directory.tables.include?(TTFunk::Table::Dsig::TAG)
          TTFunk::Table::Dsig.new(self)
        end
    end

    # Find glyph by its index.
    #
    # @return [TTFunk::Table::Cff::Charstring] if it's a CFF-based OpenType font
    # @return [TTFunk::Table::Glyf::Simple, TTFunk::Table::Glyf::Compound]
    #   if it's a TrueType font
    def find_glyph(glyph_id)
      if cff.exists?
        cff.top_index[0].charstrings_index[glyph_id].glyph
      else
        glyph_outlines.for(glyph_id)
      end
    end
  end
end

require_relative 'ttfunk/table/cff'
require_relative 'ttfunk/table/cmap'
require_relative 'ttfunk/table/dsig'
require_relative 'ttfunk/table/glyf'
require_relative 'ttfunk/table/head'
require_relative 'ttfunk/table/hhea'
require_relative 'ttfunk/table/hmtx'
require_relative 'ttfunk/table/kern'
require_relative 'ttfunk/table/loca'
require_relative 'ttfunk/table/maxp'
require_relative 'ttfunk/table/name'
require_relative 'ttfunk/table/os2'
require_relative 'ttfunk/table/post'
require_relative 'ttfunk/table/sbix'
require_relative 'ttfunk/table/vorg'
