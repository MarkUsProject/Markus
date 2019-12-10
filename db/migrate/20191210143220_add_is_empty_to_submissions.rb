class AddIsEmptyToSubmissions < ActiveRecord::Migration[6.0]
  def change
    add_column :submissions, :is_empty, :boolean, null: false, default: true
  end
end
