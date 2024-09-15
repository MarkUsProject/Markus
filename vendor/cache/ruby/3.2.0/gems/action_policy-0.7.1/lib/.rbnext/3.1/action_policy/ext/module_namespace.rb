# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add Module#namespace method
    module ModuleNamespace # :nodoc: all
      unless "".respond_to?(:safe_constantize)
        require "action_policy/ext/string_constantize"
        using ActionPolicy::Ext::StringConstantize
      end

      module Ext
        def namespace
          return unless name&.match?(/[^^]::/)

          name.sub(/::[^:]+$/, "").safe_constantize
        end
      end

      # See https://github.com/jruby/jruby/issues/5220
      ::Module.include(Ext) if RUBY_PLATFORM.match?(/java/i)

      refine Module do
        if RUBY_VERSION <= "2.7.0"
          include Ext
        else
          ::RubyNext::Core.import_methods(Ext, binding)
        end
      end
    end
  end
end
