class Token < ApplicationRecord

  belongs_to :grouping, required: true

  validates_presence_of :remaining
  validates_numericality_of :remaining, only_integer: true, greater_than_or_equal_to: 0

  def calculate_remaining!
    assignment = grouping.assignment
    if Time.current < assignment.token_start_date || !grouping.is_valid?
      self.remaining = 0
    elsif assignment.unlimited_tokens
      # grouping has 1 token that is never consumed
      self.remaining = 1
    elsif self.last_used.nil?
      self.remaining = assignment.tokens_per_period
    else
      # divide time into chunks of token_period hours
      # recharge tokens only the first time they are used during the current chunk
      hours_from_start = (Time.current - assignment.token_start_date) / 3600
      periods_from_start = (hours_from_start / assignment.token_period).floor
      last_period_begin = assignment.token_start_date + (periods_from_start * assignment.token_period).hours
      if self.last_used < last_period_begin
        self.remaining = assignment.tokens_per_period
      end
    end
    self.save
  end

  # Decreases the number of tokens by one, or raises an exception if there are no remaining tokens.
  def decrease_remaining!
    if self.remaining > 0
      self.remaining -= 1
      self.last_used = Time.current
      self.save
    else
      raise I18n.t('automated_tests.error.no_tokens')
    end
  end

  # Update the number of tokens based on the old and new token limits
  def update_tokens(old_limit, new_limit)
    difference = new_limit - old_limit
    self.remaining = [self.remaining + difference, 0].max
    self.save
  end
end
