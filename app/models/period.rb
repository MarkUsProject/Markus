class Period < ActiveRecord::Base
  #validates_presence_of     :start_time, :end_time, :submission_rule_id
  #validates_presence_of     :type, :deduction
  #validates_associated      :submission_rule_id
  belongs_to :submission_rule, :polymorphic => true
end
