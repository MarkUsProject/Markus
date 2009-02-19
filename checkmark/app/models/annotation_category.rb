class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :annotation_labels
  belongs_to :assignment
  validates_uniqueness_of :name, :message => 'is already taken'
end
