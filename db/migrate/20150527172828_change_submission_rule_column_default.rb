class ChangeSubmissionRuleColumnDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :submission_rules, :type, 'NoLateSubmissionRule'
  end

  def down
    change_column_default :submission_rules, :type, 'NullSubmissionRule'
  end
end
