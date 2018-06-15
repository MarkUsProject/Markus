class CreateMarkingSchemes < ActiveRecord::Migration[4.2]
  def change
    create_table :marking_schemes do |t|
      t.string :name

      t.timestamps
    end
  end
end
