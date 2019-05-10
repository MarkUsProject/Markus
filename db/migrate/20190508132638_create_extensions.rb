class CreateExtensions < ActiveRecord::Migration[5.2]
  def change
    create_table :extensions do |t|
      t.integer :time_delta, null: false
      t.boolean :apply_penalty, null: false, default: false
      t.references :grouping, index: { unique: true }, foreign_key: true
      t.string :note

      t.timestamps null: false
    end
  end
end
