class AddDetailsToExamTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :exam_templates, :cover_fields, :string, :default => ""
    add_column :exam_templates, :automatic_parsing, :boolean, :default => false
    add_column :exam_templates, :crop_x, :decimal
    add_column :exam_templates, :crop_y, :decimal
    add_column :exam_templates, :crop_width, :decimal
    add_column :exam_templates, :crop_height, :decimal
  end
end
