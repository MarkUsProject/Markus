module PolicyHelper
  class PolicyMatcher
    def initialize(function, because_of: nil)
      @function = function
      @because_of = because_of
    end

    def matches?(policy)
      @policy = policy
      @policy.apply(@function)
    end

    def does_not_match?(policy)
      @policy = policy
      passed = @policy.apply(@function)
      if passed
        return false
      end
      if @because_of.nil?
        return true
      end
      reasons = @policy.result.reasons.reasons
      # reasons' values are arrays
      if @because_of.is_a?(Hash)
        reasons.any? { |clazz, functions| functions.include?(@because_of[clazz]) }
      else
        reasons[policy.class].include?(@because_of)
      end
    end

    def description
      if @because_of.nil?
        'pass'
      else
        "pass because of \"#{@because_of}\""
      end
    end

    def failure_message
      "it did not pass because of \"#{@policy.result.reasons.reasons}\""
    end

    def failure_message_when_negated
      'it passed'
    end
  end

  def pass(function, because_of: nil)
    PolicyMatcher.new(function, because_of: because_of)
  end
end
