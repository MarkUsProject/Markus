class AddAssociatedCriterionToTestScripts < ActiveRecord::Migration
  def change
    add_reference :test_scripts, :criterion, polymorphic: true, index: true 
  end
end
