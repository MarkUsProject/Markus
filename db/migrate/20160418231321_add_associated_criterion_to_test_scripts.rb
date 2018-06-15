class AddAssociatedCriterionToTestScripts < ActiveRecord::Migration[4.2]
  def change
    add_reference :test_scripts, :criterion, polymorphic: true, index: true
  end
end
