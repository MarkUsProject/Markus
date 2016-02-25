class RemoveRemarkResultFromSubmission < ActiveRecord::Migration
  def change
    change_table :submissions do |t|
      t.remove :remark_result_id
    end
  end
end
