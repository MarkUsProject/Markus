## 
# Extend Time class to offset the time that 'now' returns.  This
# provides the opening to "warp time" for any tests checking for
# time-based limitations.  Perhaps one needs to check hourly
# limits, common time borders like midnight, etc.
if !Time.respond_to?(:real_now)  # assures there is no infinite looping when aliasing #now
  Time.class_eval do
    class << self
      attr_accessor :testing_offset
      
      alias_method :real_now, :now
      def now
        real_now.class.at(real_now - Time.testing_offset)
      end

      alias_method :real_new, :new
      def self.new(*args)
        args.empty? ? now : real_new(*args)
      end
    end
  end
end
Time.testing_offset = 0