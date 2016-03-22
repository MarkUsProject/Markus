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
      self.last_token_used_date = Time.now
    end
    self.save
  end

  def reassign_tokens_if_after_regen_period(regeneration_period)
    if self.last_token_used_date
      if (self.last_token_used_date.to_i + regeneration_period*60*60) <= Time.now.to_i
        self.reassign_tokens
      end
    else
      self.reassign_tokens
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
