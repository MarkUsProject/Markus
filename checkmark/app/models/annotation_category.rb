class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :annotation_labels
  validates_uniqueness_of :name, :message => 'is already taken'
end
