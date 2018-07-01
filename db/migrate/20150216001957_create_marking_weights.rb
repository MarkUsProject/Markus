class CreateMarkingWeights < ActiveRecord::Migration[4.2]
  def change
    create_table :marking_weights do |t|
      t.integer :ms_id
      t.integer :a_id
      t.decimal :weight

      t.timestamps
    end
  end
end
