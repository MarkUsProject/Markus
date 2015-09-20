class ChangeSubmissionRuleColumnDefault < ActiveRecord::Migration
  def up
    change_column_default :submission_rules, :type, 'NoLateSubmissionRule'
  end

  def down
    change_column_default :submission_rules, :type, 'NullSubmissionRule'
  end
end
