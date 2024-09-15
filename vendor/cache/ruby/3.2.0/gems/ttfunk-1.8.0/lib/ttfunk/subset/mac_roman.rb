# frozen_string_literal: true

require 'set'

require_relative 'code_page'

module TTFunk
  module Subset
    # Mac Roman subset. It uses code page 10,000 and Mac OS Roman encoding.
    class MacRoman < CodePage
      # @param original [TTFunk::File]
      def initialize(original)
        super(original, 10_000, Encoding::MACROMAN)
      end
    end
  end
end
