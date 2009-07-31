class AnnotationText < ActiveRecord::Base
  belongs_to :annotation_category
  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, :dependent => :destroy
  validates_associated      :annotation_category, :message => 'annotation_category associations failed'

end
