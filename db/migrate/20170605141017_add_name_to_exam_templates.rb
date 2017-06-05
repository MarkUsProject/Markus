class AddNameToExamTemplates < ActiveRecord::Migration
  def change
    add_column :exam_templates, :name, :string, null: false, unique: true
  end
end
