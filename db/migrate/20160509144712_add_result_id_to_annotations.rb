class AddResultIdToAnnotations < ActiveRecord::Migration
  def change
    add_reference :annotations, :result
  end
end
