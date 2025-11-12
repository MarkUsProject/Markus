class AddPenaltyTypeToSubmissionRules < ActiveRecord::Migration[8.0]
  def change
    add_column :submission_rules, :penalty_type, :string, default: 'percentage'
  end
end
