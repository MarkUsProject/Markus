class Period < ActiveRecord::Base
  validates_presence_of     :hours
  validates_associated      :submission_rule
  validates_numericality_of :hours, :greater_than_or_equal_to => 0
  belongs_to :submission_rule, :polymorphic => true
end
