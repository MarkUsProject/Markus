require 'core_ext'

module Test # :nodoc:
  module Unit # :nodoc:
    class TestCase

      ##
      # Time warp to the specified time for the duration of the passed block.
      def pretend_now_is(*args)
        begin
          Time.testing_offset = Time.now - time_from(*args)
          yield
        ensure
          Time.testing_offset = 0
        end
      end
    
    private
    
      def time_from(*args)
        return args[0] if 1 == args.size && args[0].is_a?(Time)
        Time.utc(*args)
      end

    end
  end
end