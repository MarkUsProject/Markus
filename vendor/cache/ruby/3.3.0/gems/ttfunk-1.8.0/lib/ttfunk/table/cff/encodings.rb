# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      # Predefined encodings.
      module Encodings
        autoload :EXPERT, 'ttfunk/table/cff/encodings/expert'
        autoload :STANDARD, 'ttfunk/table/cff/encodings/standard'
      end
    end
  end
end
