class AddRemarkRequestSubmittedAttoResult < ActiveRecord::Migration[4.2]
  def change
    change_table :results do |t|
      t.datetime :remark_request_submitted_at
    end
  end
end
