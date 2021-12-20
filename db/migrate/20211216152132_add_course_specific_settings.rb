class AddCourseSpecificSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :autotest_settings do |t|
      t.column :url, :string, null: false
      t.column :api_key, :string, null: false
      t.column :schema, :string, null: false
    end
    add_reference :courses, :autotest_setting, foreign_key: true
  end
end
