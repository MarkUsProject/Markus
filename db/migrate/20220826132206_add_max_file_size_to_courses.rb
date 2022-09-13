class AddMaxFileSizeToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :max_file_size, :bigint, null: false, default: 5000000
  end
end
