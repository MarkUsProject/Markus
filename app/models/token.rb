class Token < ActiveRecord::Base

  validate   :last_used_date

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

  # Each test will decrease the number of tokens by one
  def decrease_tokens
    if self.remaining > 0
      self.remaining = self.remaining - 1
      if self.last_used.nil?
        self.last_used = DateTime.now
      end
      save
    end
  end

  def reassign_tokens
    assignment = grouping.assignment
    if DateTime.now < assignment.token_start_date || !grouping.is_valid?
      self.remaining = 0
    elsif assignment.unlimited_tokens
      # grouping has  1 token that is never consumed
      self.remaining = 1
    elsif last_used.nil? ||
          (last_used.to_time.to_i + assignment.token_period * 60 * 60 <=
            DateTime.now.to_time.to_i)
      self.remaining = assignment.tokens_per_period
    end
    self.save
  end

  # Update the number of tokens based on the old and new token limits
  def update_tokens(old_limit, new_limit)
    difference = new_limit - old_limit
    self.remaining = [self.remaining + difference, 0].max
    self.save
  end
end
