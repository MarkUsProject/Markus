# frozen_string_literal: true

require_relative 'subset/unicode'
require_relative 'subset/unicode_8bit'
require_relative 'subset/mac_roman'
require_relative 'subset/windows_1252'

module TTFunk
  # Namespace for different types of subsets.
  module Subset
    # Create a subset for the font using the specified encoding.
    #
    # @param original [TTFunk::File]
    # @param encoding [:unicode, :unicode_8bit, :mac_roman, :windows_1252]
    # @raise [NotImplementedError] for unsupported encodings
    # @return [TTFunk::Subset::Unicode, TTFunk::Subset::Unicode8Bit,
    #   TTFunk::Subset::MacRoman, TTFunk::Subset::Windows1252]
    def self.for(original, encoding)
      case encoding.to_sym
      when :unicode then Unicode.new(original)
      when :unicode_8bit then Unicode8Bit.new(original)
      when :mac_roman then MacRoman.new(original)
      when :windows_1252 then Windows1252.new(original) # rubocop: disable Naming/VariableNumber
      else raise NotImplementedError, "encoding #{encoding} is not supported"
      end
    end
  end
end
