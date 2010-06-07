class Period < ActiveRecord::Base
  validates_presence_of     :hours
  validates_associated      :submission_rule
  belongs_to :submission_rule, :polymorphic => true
end
