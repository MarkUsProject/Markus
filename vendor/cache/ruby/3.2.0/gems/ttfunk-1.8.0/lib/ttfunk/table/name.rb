# frozen_string_literal: true

require_relative '../table'
require 'digest/sha1'

module TTFunk
  class Table
    # Naming (`name`) table
    class Name < Table
      # Name Record.
      class NameString < ::String
        # Platform ID.
        # @return [Integer]
        attr_reader :platform_id

        # Platform-specific encoding ID.
        # @return [Integer]
        attr_reader :encoding_id

        # Language ID.
        # @return [Integer]
        attr_reader :language_id

        # @param text [String]
        # @param platform_id [Integer]
        # @param encoding_id [Integer]
        # @param language_id [Integer]
        def initialize(text, platform_id, encoding_id, language_id)
          super(text)
          @platform_id = platform_id
          @encoding_id = encoding_id
          @language_id = language_id
        end

        # Removes chracter incompatible with PostScript.
        # @return [String] PostScript-compatible version of this string.
        def strip_extended
          stripped = gsub(/[\x00-\x19\x80-\xff]/n, '')
          stripped = '[not-postscript]' if stripped.empty?
          stripped
        end
      end

      # Name records.
      # @return [Array<Hash>]
      attr_reader :entries

      # Name strings.
      # @return [Hash{Integer => NameString}]
      attr_reader :strings

      # Copyright notice.
      # @return [Array<NameString>]
      attr_reader :copyright

      # Font Family names.
      # @return [Array<NameString>]
      attr_reader :font_family

      # Font Subfamily names.
      # @return [Array<NameString>]
      attr_reader :font_subfamily

      # Unique font identifiers.
      # @return [Array<NameString>]
      attr_reader :unique_subfamily

      # Full font names.
      # @return [Array<NameString>]
      attr_reader :font_name

      # Version strings.
      # @return [Array<NameString>]
      attr_reader :version

      # Trademarks.
      # @return [Array<NameString>]
      attr_reader :trademark

      # Manufacturer Names.
      # @return [Array<NameString>]
      attr_reader :manufacturer

      # Designers.
      # @return [Array<NameString>]
      attr_reader :designer

      # Descriptions.
      # @return [Array<NameString>]
      attr_reader :description

      # Vendor URLs.
      # @return [Array<NameString>]
      attr_reader :vendor_url

      # Designer URLs.
      # @return [Array<NameString>]
      attr_reader :designer_url

      # License Descriptions.
      # @return [Array<NameString>]
      attr_reader :license

      # License Info URLs.
      # @return [Array<NameString>]
      attr_reader :license_url

      # Typographic Family names.
      # @return [Array<NameString>]
      attr_reader :preferred_family

      # Typographic Subfamily names.
      # @return [Array<NameString>]
      attr_reader :preferred_subfamily

      # Compatible Full Names.
      # @return [Array<NameString>]
      attr_reader :compatible_full

      # Sample texts.
      # @return [Array<NameString>]
      attr_reader :sample_text

      # Copyright notice ID.
      COPYRIGHT_NAME_ID = 0

      # Font Family name ID.
      FONT_FAMILY_NAME_ID = 1

      # Font Subfamily name ID.
      FONT_SUBFAMILY_NAME_ID = 2

      # Unique font identifier ID.
      UNIQUE_SUBFAMILY_NAME_ID = 3

      # Full font name that reflects all family and relevant subfamily
      # descriptors ID.
      FONT_NAME_NAME_ID = 4

      # Version string ID.
      VERSION_NAME_ID = 5

      # PostScript name for the font ID.
      POSTSCRIPT_NAME_NAME_ID = 6

      # Trademark ID.
      TRADEMARK_NAME_ID = 7

      # Manufacturer Name ID.
      MANUFACTURER_NAME_ID = 8

      # Designer ID.
      DESIGNER_NAME_ID = 9

      # Description ID.
      DESCRIPTION_NAME_ID = 10

      # Vendor URL ID.
      VENDOR_URL_NAME_ID = 11

      # Designer URL ID.
      DESIGNER_URL_NAME_ID = 12

      # License Description ID.
      LICENSE_NAME_ID = 13

      # License Info URL ID.
      LICENSE_URL_NAME_ID = 14

      # Typographic Family name ID.
      PREFERRED_FAMILY_NAME_ID = 16

      # Typographic Subfamily name ID.
      PREFERRED_SUBFAMILY_NAME_ID = 17

      # Compatible Full ID.
      COMPATIBLE_FULL_NAME_ID = 18

      # Sample text ID.
      SAMPLE_TEXT_NAME_ID = 19

      # Encode table.
      #
      # @param names [TTFunk::Table::Name]
      # @param key [String]
      # @return [String]
      def self.encode(names, key = '')
        tag = Digest::SHA1.hexdigest(key)[0, 6]

        postscript_name = NameString.new("#{tag}+#{names.postscript_name}", 1, 0, 0)

        strings = names.strings.dup
        strings[6] = [postscript_name]
        str_count = strings.reduce(0) { |sum, (_, list)| sum + list.length }

        table = [0, str_count, 6 + (12 * str_count)].pack('n*')
        strtable = +''

        items = []
        strings.each do |id, list|
          list.each do |string|
            items << [id, string]
          end
        end
        items =
          items.sort_by { |id, string|
            [string.platform_id, string.encoding_id, string.language_id, id]
          }
        items.each do |id, string|
          table << [
            string.platform_id, string.encoding_id, string.language_id, id,
            string.length, strtable.length,
          ].pack('n*')
          strtable << string
        end

        table << strtable
      end

      # PostScript name for the font.
      # @return [String]
      def postscript_name
        return @postscript_name if @postscript_name

        font_family.first || 'unnamed'
      end

      private

      def parse!
        count, string_offset = read(6, 'x2n*')

        @entries = []
        count.times do
          platform, encoding, language, id, length, start_offset =
            read(12, 'n*')
          @entries << {
            platform_id: platform,
            encoding_id: encoding,
            language_id: language,
            name_id: id,
            length: length,
            offset: offset + string_offset + start_offset,
            text: nil,
          }
        end

        @strings = Hash.new { |h, k| h[k] = [] }

        count.times do |i|
          io.pos = @entries[i][:offset]
          @entries[i][:text] = io.read(@entries[i][:length])
          @strings[@entries[i][:name_id]] << NameString.new(
            @entries[i][:text] || '',
            @entries[i][:platform_id],
            @entries[i][:encoding_id],
            @entries[i][:language_id],
          )
        end

        # should only be ONE postscript name

        @copyright = @strings[COPYRIGHT_NAME_ID]
        @font_family = @strings[FONT_FAMILY_NAME_ID]
        @font_subfamily = @strings[FONT_SUBFAMILY_NAME_ID]
        @unique_subfamily = @strings[UNIQUE_SUBFAMILY_NAME_ID]
        @font_name = @strings[FONT_NAME_NAME_ID]
        @version = @strings[VERSION_NAME_ID]

        unless @strings[POSTSCRIPT_NAME_NAME_ID].empty?
          @postscript_name = @strings[POSTSCRIPT_NAME_NAME_ID]
            .first.strip_extended
        end

        @trademark = @strings[TRADEMARK_NAME_ID]
        @manufacturer = @strings[MANUFACTURER_NAME_ID]
        @designer = @strings[DESIGNER_NAME_ID]
        @description = @strings[DESCRIPTION_NAME_ID]
        @vendor_url = @strings[VENDOR_URL_NAME_ID]
        @designer_url = @strings[DESIGNER_URL_NAME_ID]
        @license = @strings[LICENSE_NAME_ID]
        @license_url = @strings[LICENSE_URL_NAME_ID]
        @preferred_family = @strings[PREFERRED_FAMILY_NAME_ID]
        @preferred_subfamily = @strings[PREFERRED_SUBFAMILY_NAME_ID]
        @compatible_full = @strings[COMPATIBLE_FULL_NAME_ID]
        @sample_text = @strings[SAMPLE_TEXT_NAME_ID]
      end
    end
  end
end
