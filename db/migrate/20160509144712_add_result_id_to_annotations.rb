class AddResultIdToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_reference :annotations, :result
  end
end
