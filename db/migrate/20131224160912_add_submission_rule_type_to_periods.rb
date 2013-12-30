class AddSubmissionRuleTypeToPeriods < ActiveRecord::Migration
  def change
    add_column :periods, :submission_rule_type, :string
  end
end
