class ChangeNameLimitInExamTemplatesAndTags < ActiveRecord::Migration[8.1]
  def up
    change_column :exam_templates, :name, :string, limit: 20, null: false
    change_column :tags, :name, :string, limit: 30, null: false
  end

  def down
    change_column :exam_templates, :name, :string, limit: nil, null: false
    change_column :tags, :name, :string, limit: nil, null: false
  end
end
