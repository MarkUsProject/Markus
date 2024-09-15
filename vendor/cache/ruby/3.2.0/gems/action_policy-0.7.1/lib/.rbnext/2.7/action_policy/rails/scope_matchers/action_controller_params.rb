# frozen_string_literal: true

module ActionPolicy
  module ScopeMatchers
    # Adds `params_filter` method as an alias
    # for `scope_for :action_controller_params`
    module ActionControllerParams
      def params_filter(*__rest__, &__block__)
        scope_for(:action_controller_params, *__rest__, &__block__)
      end; respond_to?(:ruby2_keywords, true) && (ruby2_keywords :params_filter)
    end
  end
end

# Add alias to base policy
ActionPolicy::Base.extend ActionPolicy::ScopeMatchers::ActionControllerParams

ActiveSupport.on_load(:action_controller) do
  # Register params scope matcher
  ActionPolicy::Base.scope_matcher :action_controller_params, ActionController::Parameters
end
