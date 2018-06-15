class AddNameToExamTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_templates, :name, :string, null: false, unique: true
  end
end
