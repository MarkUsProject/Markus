class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :annotation_labels
  belongs_to :assignment
  validates_uniqueness_of :name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :assignment_id
  validates_associated :assignment, :message => 'not strongly associated with assignment'
end
