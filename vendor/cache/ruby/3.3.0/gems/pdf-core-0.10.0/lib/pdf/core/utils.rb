# frozen_string_literal: true

module PDF
  module Core
    # Utility methods
    module Utils
      module_function

      # Deep clone an object.
      # It uses marshal-demarshal trick. Since it's supposed to be use only on
      # objects that can be serialized into PDF it shouldn't have any issues
      # with objects that can not be marshaled.
      #
      # @param object [any]
      # @return [any]
      def deep_clone(object)
        Marshal.load(Marshal.dump(object))
      end
    end
  end
end
