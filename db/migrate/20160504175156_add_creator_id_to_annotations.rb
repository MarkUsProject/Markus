class AddCreatorIdToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_reference :annotations, :creator, polymorphic: true, index: true
  end
end
