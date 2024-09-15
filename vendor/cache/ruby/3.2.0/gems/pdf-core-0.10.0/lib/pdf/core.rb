# frozen_string_literal: true

# Top level Module
module PDF
  # PDF::Core is concerned with low-level PDF functions such as serialization,
  # content streams and such.
  #
  # It's extracted from Prawn but at the moment is not entirely independent.
  module Core
    # PDF::Core-specific errors
    module Errors
      # This error indicates failure of {PDF::Core.pdf_object}
      class FailedObjectConversion < StandardError
      end

      # This error occurs when a graphic state is being restored but the graphic
      # state stack is empty.
      class EmptyGraphicStateStack < StandardError
      end

      # This error is raised when page layout is set to anything other than
      # `:portrait` or `:landscape`
      class InvalidPageLayout < StandardError
      end
    end
  end
end

require_relative 'core/pdf_object'
require_relative 'core/annotations'
require_relative 'core/byte_string'
require_relative 'core/destinations'
require_relative 'core/filters'
require_relative 'core/stream'
require_relative 'core/reference'
require_relative 'core/literal_string'
require_relative 'core/filter_list'
require_relative 'core/page'
require_relative 'core/object_store'
require_relative 'core/document_state'
require_relative 'core/name_tree'
require_relative 'core/graphics_state'
require_relative 'core/page_geometry'
require_relative 'core/outline_root'
require_relative 'core/outline_item'
require_relative 'core/renderer'
require_relative 'core/text'
