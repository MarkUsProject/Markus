class CreateSectionHiddens < ActiveRecord::Migration[6.1]
  def change
    create_table :section_hiddens do |t|
      t.boolean :is_hidden
      t.references :section, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
