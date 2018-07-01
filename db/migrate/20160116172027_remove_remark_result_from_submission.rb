class RemoveRemarkResultFromSubmission < ActiveRecord::Migration[4.2]
  def change
    change_table :submissions do |t|
      t.remove :remark_result_id
    end
  end
end
