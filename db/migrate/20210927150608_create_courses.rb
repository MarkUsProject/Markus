class CreateCourses < ActiveRecord::Migration[6.1]
  def change
    create_table :courses do |t|
      t.string :name, null: false, unique: true
      t.boolean :is_hidden, null: false, default: true
      t.string :display_name, null: false

      t.timestamps
    end
  end
end
