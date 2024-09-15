require 'ostruct'

module Shoulda # :nodoc:
  module Callback # :nodoc:
    module Matchers # :nodoc:
      module ActiveModel # :nodoc:

        # Ensures that the given model has a callback defined for the given method
        #
        # Options:
        # * <tt>before(:lifecycle)</tt>. <tt>Symbol</tt>. - define the callback as a callback before the fact. :lifecycle can be :save, :create, :update, :destroy, :validation
        # * <tt>after(:lifecycle)</tt>. <tt>Symbol</tt>. - define the callback as a callback after the fact. :lifecycle can be :save, :create, :update, :destroy, :validation, :initialize, :find, :touch
        # * <tt>around(:lifecycle)</tt>. <tt>Symbol</tt>. - define the callback as a callback around the fact. :lifecycle can be :save, :create, :update, :destroy
        #   <tt>if(:condition)</tt>. <tt>Symbol</tt>. - add a positive condition to the callback to be matched against
        #   <tt>unless(:condition)</tt>. <tt>Symbol</tt>. - add a negative condition to the callback to be matched against
        #
        # Examples:
        #   it { should callback(:method).after(:create) }
        #   it { should callback(:method).before(:validation).unless(:should_it_not?) }
        #   it { should callback(CallbackClass).before(:validation).unless(:should_it_not?) }
        #
        def callback method
          CallbackMatcher.new method
        end

        class CallbackMatcher # :nodoc:
          VALID_OPTIONAL_LIFECYCLES = [:validation, :commit, :rollback].freeze
          
          include RailsVersionHelper
          
          def initialize method
            @method = method
          end
        
          # @todo replace with %i() as soon as 1.9 is deprecated
          [:before, :after, :around].each do |hook|
            define_method hook do |lifecycle|
              @hook = hook
              @lifecycle = lifecycle
              check_for_undefined_callbacks!
              
              self
            end
          end
        
          [:if, :unless].each do |condition_type|
            define_method condition_type do |condition|
              @condition_type = condition_type
              @condition = condition

              self
            end
          end
        
          def on optional_lifecycle
            check_for_valid_optional_lifecycles!
            
            @optional_lifecycle = optional_lifecycle
          
            self
          end

          def matches? subject
            check_preconditions!
            
            callbacks = subject.send :"_#{@lifecycle}_callbacks"
            callbacks.any? do |callback|
              has_callback?(subject, callback) &&
              matches_hook?(callback) && 
              matches_conditions?(callback) && 
              matches_optional_lifecycle?(callback) &&
              callback_method_exists?(subject, callback)
            end
          end
          
          def callback_method_exists? object, callback
            if is_class_callback?(object, callback) && !callback_object(object, callback).respond_to?(:"#{@hook}_#{@lifecycle}", true)
              @failure_message = "callback #{@method} is listed as a callback #{@hook} #{@lifecycle}#{optional_lifecycle_phrase}#{condition_phrase}, but the given object does not respond to #{@hook}_#{@lifecycle} (using respond_to?(:#{@hook}_#{@lifecycle}, true)"
              false
            elsif !is_class_callback?(object, callback) && !object.respond_to?(callback.filter, true)
              @failure_message = "callback #{@method} is listed as a callback #{@hook} #{@lifecycle}#{optional_lifecycle_phrase}#{condition_phrase}, but the model does not respond to #{@method} (using respond_to?(:#{@method}, true)"
              false
            else
              true
            end
          end
        
          def failure_message
            @failure_message || "expected #{@method} to be listed as a callback #{@hook} #{@lifecycle}#{optional_lifecycle_phrase}#{condition_phrase}, but was not"
          end
        
          def failure_message_when_negated
            @failure_message || "expected #{@method} not to be listed as a callback #{@hook} #{@lifecycle}#{optional_lifecycle_phrase}#{condition_phrase}, but was"
          end

          def negative_failure_message
            failure_message_when_negated
          end

          def description
            "callback #{@method} #{@hook} #{@lifecycle}#{optional_lifecycle_phrase}#{condition_phrase}"
          end
          
          private
          
          def check_preconditions!
            check_lifecycle_present!
          end
          
          def check_lifecycle_present!
            unless @lifecycle
              raise UsageError, "callback #{@method} can not be tested against an undefined lifecycle, use .before, .after or .around", caller
            end
          end
          
          def check_for_undefined_callbacks!
            if [:rollback, :commit].include?(@lifecycle) && @hook != :after
              raise UsageError, "Can not callback before or around #{@lifecycle}, use after.", caller
            end
          end
          
          def check_for_valid_optional_lifecycles!
            unless VALID_OPTIONAL_LIFECYCLES.include?(@lifecycle)
              raise UsageError, "The .on option is only valid for #{VALID_OPTIONAL_LIFECYCLES.to_sentence} and cannot be used with #{@lifecycle}, use with .before(:validation) or .after(:validation)", caller
            end
          end
          
          def precondition_failed?
            @failure_message.present?
          end
          
          def matches_hook? callback
            callback.kind == @hook
          end

          def has_callback? subject, callback
            has_callback_object?(subject, callback) || has_callback_method?(callback) || has_callback_class?(callback)
          end
          
          def has_callback_method? callback
            callback.filter == @method
          end
          
          def has_callback_class? callback
            class_callback_required? && callback.filter.is_a?(@method)
          end

          def has_callback_object? subject, callback
            callback.filter.respond_to?(:match) &&
            callback.filter.match(/\A_callback/) && 
            subject.respond_to?(:"#{callback.filter}_object") && 
            callback_object(subject, callback).class == @method 
          end
          
          def matches_conditions? callback
            if rails_version >= '4.1'
              !@condition || callback.instance_variable_get(:"@#{@condition_type}").include?(@condition)
            else
              !@condition || callback.options[@condition_type].include?(@condition)
            end
          end
        
          def matches_optional_lifecycle? callback
            if rails_version >= '4.1'
              if_conditions = callback.instance_variable_get(:@if)
              !@optional_lifecycle || if_conditions.include?(lifecycle_context_string) || active_model_proc_matches_optional_lifecycle?(if_conditions)
            else
              !@optional_lifecycle || callback.options[:if].include?(lifecycle_context_string)
            end
          end
        
          def condition_phrase
            " #{@condition_type} #{@condition} evaluates to #{@condition_type == :if ? 'true' : 'false'}" if @condition
          end
        
          def optional_lifecycle_phrase
            " on #{@optional_lifecycle}" if @optional_lifecycle
          end
          
          def lifecycle_context_string
            if rails_version >= '4.0'
              rails_4_lifecycle_context_string
            else
              rails_3_lifecycle_context_string
            end
          end
          
          def rails_3_lifecycle_context_string
            if @lifecycle == :validation
              "self.validation_context == :#{@optional_lifecycle}"
            else
              "transaction_include_action?(:#{@optional_lifecycle})"
            end
          end
          
          def rails_4_lifecycle_context_string
            if @lifecycle == :validation
              "[:#{@optional_lifecycle}].include? self.validation_context"
            else
              "transaction_include_any_action?([:#{@optional_lifecycle}])"
            end
          end
          
          def active_model_proc_matches_optional_lifecycle? if_conditions
            if_conditions.select{|i| i.is_a? Proc }.any? do |condition|
              condition.call ValidationContext.new(@optional_lifecycle)
            end
          end
          
          def class_callback_required?
            !@method.is_a?(Symbol) && !@method.is_a?(String)
          end
          
          def is_class_callback? subject, callback
            !callback_object(subject, callback).is_a?(Symbol) && !callback_object(subject, callback).is_a?(String)
          end
          
          def callback_object subject, callback
            if (rails_version >= '3.0' && rails_version < '4.1') && !callback.filter.is_a?(Symbol)
              subject.send("#{callback.filter}_object")
            else
              callback.filter
            end
          end

        end
        
        ValidationContext = Struct.new :validation_context
        UsageError = Class.new NameError
      end
    end
  end
end
