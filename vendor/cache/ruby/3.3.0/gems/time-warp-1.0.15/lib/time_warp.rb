require File.join File.dirname(__FILE__), 'core_ext'

module TimeWarpAbility

    def reset_to_real_time
      Time.testing_offset = 0
    end

    def pretend_now_is(*args)
      Time.testing_offset = Time.now - time_from(*args)
      if block_given?
        begin
          yield
        ensure
          reset_to_real_time
        end
      end
    end

  private

    def time_from(*args)
      return args[0] if 1 == args.size && args[0].is_a?(Time)
      return args[0].to_time if 1 == args.size && args[0].respond_to?(:to_time)  # For example, if it's a Date.
      Time.utc(*args)
    end
end

module Test # :nodoc:
  module Unit # :nodoc:
    class TestCase
      include ::TimeWarpAbility
    end
  end
end

module MiniTest
  class Unit
    class TestCase
      include ::TimeWarpAbility
    end
  end
end

module RSpec
  module Core
    class ExampleGroup
      include ::TimeWarpAbility
     # Time warp to the specified time for the duration of the passed block.
    end
  end
end

module Minitest
  class Test
    include ::TimeWarpAbility
  end
end
