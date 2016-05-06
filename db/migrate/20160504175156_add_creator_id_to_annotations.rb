class AddCreatorIdToAnnotations < ActiveRecord::Migration
  def change
    add_reference :annotations, :creator, polymorphic: true, index: true
  end
end
