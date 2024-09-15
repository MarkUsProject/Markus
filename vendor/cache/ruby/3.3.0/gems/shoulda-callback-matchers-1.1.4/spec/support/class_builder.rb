module ClassBuilder
  def self.included example_group
    example_group.class_eval do
      after do
        teardown_defined_constants
      end
    end
  end

  def define_class class_name, base = Object, &block
    Object.const_set class_name, Class.new(base)
    
    Object.const_get(class_name).tap do |constant_class|
      constant_class.unloadable

      if block_given?
        constant_class.class_eval(&block)
      end

      if constant_class.respond_to?(:reset_column_information)
        constant_class.reset_column_information
      end
    end
  end

  def teardown_defined_constants
    ActiveSupport::Dependencies.clear
  end
end