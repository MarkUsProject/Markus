require 'date'

# Extend Date class to generate 'today' from modified Time.now
Date.class_eval do
  class << self

    def today
      Time.now.send(:to_date)
    end

  end
  
end
  