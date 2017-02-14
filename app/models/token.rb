class Token < ActiveRecord::Base

  validate :last_used_date

  belongs_to :grouping
  validates_presence_of :grouping_id, :remaining

  validates_numericality_of :remaining,
                            only_integer: true,
                            greater_than_or_equal_to: 0

  def last_used_date
    if self.last_used && Time.zone.parse(self.last_used.to_s).nil?
      errors.add :last_used, 'is not a valid date'
      false
    else
      true
    end
  end

  def reassign_tokens
    assignment = grouping.assignment
    if Time.zone.now < assignment.token_start_date || !grouping.is_valid?
      self.remaining = 0
    elsif assignment.unlimited_tokens
      # grouping has 1 token that is never consumed
      self.remaining = 1
    elsif self.last_used.nil? || (self.last_used + assignment.token_period.hours) < Time.zone.now
      self.remaining = assignment.tokens_per_period
    end
    self.save
  end

  # Each test will decrease the number of tokens by one
  def decrease_tokens
    if self.remaining > 0
      self.remaining -= 1
      self.last_used = Time.zone.now
      self.save
    else
      raise I18n.t('automated_tests.error.no_tokens')
    end
  end

  # Checks whether a test using tokens is currently being enqueued for execution
  # (with buffer time in case of unhandled errors that prevented a test result to be stored)
  def enqueued?
    buffer_time = MarkusConfigurator.markus_ate_experimental_student_tests_buffer_time
    if self.last_used.nil? || (self.last_used + buffer_time) < Time.zone.now
      # first test or buffer time expired (in case some unhandled problem happened)
      false
    else
      last_result_time = self.grouping.student_test_script_results
                                      .limit(1)
                                      .pluck(:created_at)
      if !last_result_time.empty? && self.last_used < last_result_time[0]
        # test results already came back
        false
      else
        true
      end
    end
  end

  # Update the number of tokens based on the old and new token limits
  def update_tokens(old_limit, new_limit)
    difference = new_limit - old_limit
    self.remaining = [self.remaining + difference, 0].max
    self.save
  end
end
