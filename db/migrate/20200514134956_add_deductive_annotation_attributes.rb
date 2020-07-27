class AddDeductiveAnnotationAttributes < ActiveRecord::Migration[6.0]
  def change
    add_reference :annotation_categories,
                  :flexible_criterion,
                  foreign_key: true

    add_column :annotation_texts,
               :deduction,
               :float

    add_column :marks,
               :override,
               :boolean,
               default: false,
               null: false
  end
end
