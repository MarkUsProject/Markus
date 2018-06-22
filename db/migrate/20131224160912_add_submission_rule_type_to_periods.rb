class AddSubmissionRuleTypeToPeriods < ActiveRecord::Migration[4.2]
  def change
    add_column :periods, :submission_rule_type, :string
  end
end
