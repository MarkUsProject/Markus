class Token < ActiveRecord::Base

  belongs_to :grouping

  validates_presence_of :grouping_id, :tokens
  validates_numericality_of :tokens, :only_integer => true,  :greater_than_or_equal_to => 0
  
  # Each test will decrease the number of tokens
  # by one
  def decrease_tokens()
    if self.tokens > 0
      self.tokens = self.tokens - 1
    end
    self.save
  end

  # Re-assign to the student the nomber of tokens 
  # allowed for this assignment
  def reassign_tokens()
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
