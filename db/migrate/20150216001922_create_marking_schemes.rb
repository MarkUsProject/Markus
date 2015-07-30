class CreateMarkingSchemes < ActiveRecord::Migration
  def change
    create_table :marking_schemes do |t|
      t.string :name

      t.timestamps
    end
  end
end
