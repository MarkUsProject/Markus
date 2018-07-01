class CreateJobMessengers < ActiveRecord::Migration[4.2]
  def change
    create_table :job_messengers do |t|
      t.string :job_id, index: true
      t.string :status
      t.string :message
      t.timestamps null: false
    end
  end
end
