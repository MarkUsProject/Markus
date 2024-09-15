# frozen_string_literal: true

require_relative 'subset'

module TTFunk
  # Subset collection.
  #
  # For many use cases a font subset can be efficiently encoded using MacRoman
  # encoding. However, for full font coverage and characters that are not in
  # MacRoman encoding an additional Unicode subset is used. There can be as many
  # as needed Unicode subsets to fully cover glyphs provided by the original
  # font. Ther resulting set of subsets all use 8-bit encoding helping to
  # efficiently encode text in Prawn.
  class SubsetCollection
    # @param original [TTFunk::File]
    def initialize(original)
      @original = original
      @subsets = [Subset.for(@original, :mac_roman)]
    end

    # Get subset by index.
    #
    # @param subset [Integer]
    # @return [TTFunk::Subset::Unicode, TTFunk::Subset::Unicode8Bit,
    #   TTFunk::Subset::MacRoman, TTFunk::Subset::Windows1252]
    def [](subset)
      @subsets[subset]
    end

    # Add chracters to appropiate subsets.
    #
    # @param characters [Array<Integer>] should be an array of UTF-16 code
    #   points
    # @return [void]
    def use(characters)
      characters.each do |char|
        covered = false
        i = 0
        length = @subsets.length
        while i < length
          subset = @subsets[i]
          if subset.covers?(char)
            subset.use(char)
            covered = true
            break
          end
          i += 1
        end

        unless covered
          @subsets << Subset.for(@original, :unicode_8bit)
          @subsets.last.use(char)
        end
      end
    end

    # Encode characters into subset-character pairs.
    #
    # @param characters [Array<Integer>] should be an array of UTF-16 code
    #   points
    # @return [Array<Array(Integer, String)>] subset chunks, where each chunk
    #   is another array of two elements. The first element is the subset
    #   number, and the second element is the string of characters to render
    #   with that font subset. The strings will be encoded for their subset
    #   font, and so may not look (in the raw) like what was passed in, but they
    #   will render correctly with the corresponding subset font.
    def encode(characters)
      return [] if characters.empty?

      # TODO: probably would be more optimal to nix the #use method,
      # and merge it into this one, so it can be done in a single
      # pass instead of two passes.
      use(characters)

      parts = []
      current_subset = 0
      current_char = 0
      char = characters[current_char]

      loop do
        while @subsets[current_subset].includes?(char)
          char = @subsets[current_subset].from_unicode(char)

          if parts.empty? || parts.last[0] != current_subset
            encoded_char = char.chr
            if encoded_char.respond_to?(:force_encoding)
              encoded_char.force_encoding('ASCII-8BIT')
            end
            parts << [current_subset, encoded_char]
          else
            parts.last[1] << char
          end

          current_char += 1
          return parts if current_char >= characters.length

          char = characters[current_char]
        end

        current_subset = (current_subset + 1) % @subsets.length
      end
    end
  end
end
