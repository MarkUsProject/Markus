class AnnotationText < ActiveRecord::Base
  belongs_to :annotation_category
  validates_associated      :annotation_category, :message => 'annotation_category associations failed'

end
