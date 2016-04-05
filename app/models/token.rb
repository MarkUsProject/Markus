class Token < ActiveRecord::Base

  validate   :last_used_date

  belongs_to :grouping
  validates_presence_of :grouping_id, :tokens

  validates_numericality_of :tokens,
                            only_integer: true,
                            greater_than_or_equal_to: 0

  def last_used_date
    if self.last_token_used_date
      if Time.zone.parse(self.last_token_used_date.to_s).nil?
        errors.add :last_token_used_date, 'is not a valid date'
        false
      else
        true
      end
    end
  end

  # Each test will decrease the number of tokens
  # by one
  def decrease_tokens
    if self.tokens > 0
      self.tokens = self.tokens - 1
      self.last_token_used_date = Date.today
    end
    self.save
  end

  def reassign_tokens_if_after_regen_period()
    assignment = self.grouping.assignment
    if assignment.last_token_regeneration_date
      if (assignment.last_token_regeneration_date.to_time.to_i + assignment.regeneration_period*60*60) <= DateTime.now.to_time.to_i
        self.reassign_tokens
      end
    end
  end

  # Re-assign to the student the number of tokens
  # allowed for this assignment
  def reassign_tokens
    assignment = self.grouping.assignment
    if assignment.tokens_per_day.nil?
      self.tokens = 0
    else
      self.tokens = assignment.tokens_per_day
      num_periods = ((DateTime.now.to_time.to_i - assignment.tokens_start_of_availability_date.to_time.to_i)/60/60) / assignment.regeneration_period
      assignment.last_token_regeneration_date = assignment.tokens_start_of_availability_date +
          (num_periods.floor * assignment.regeneration_period).hours
    end
    self.save
  end

  # Update the number of tokens based on the old and new token limits
  def update_tokens(old_limit, new_limit)
    difference = new_limit - old_limit
    self.tokens = [self.tokens + difference, 0].max
    self.save
  end

end
