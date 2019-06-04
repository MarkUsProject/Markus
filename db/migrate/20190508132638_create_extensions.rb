class CreateExtensions < ActiveRecord::Migration[5.2]
  def change
    create_table :extensions do |t|
      t.string :time_delta, null: false
      t.boolean :apply_penalty, null: false, default: false
      t.references :grouping, index: { unique: true }, foreign_key: true, null: false
      t.string :note

      t.timestamps null: false
    end
  end
end
