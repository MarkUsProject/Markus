class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :annotation_category_name
  has_many :annotation_texts, :dependent => :destroy
  belongs_to :assignment
  validates_uniqueness_of :annotation_category_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :assignment_id
  validates_associated :assignment, :message => 'not strongly associated with assignment'
end
