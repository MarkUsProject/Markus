class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :annotation_category_name
  has_many :annotation_texts, :dependent => :destroy
  belongs_to :assignment
  validates_uniqueness_of :annotation_category_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :assignment_id
  validates_associated :assignment, :message => 'not strongly associated with assignment'
  
  # Takes an array of comma separated values, and tries to assemble an 
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,annotation_text,annotation_text,...
  # Returns true on success, false on failure.
  def self.add_by_row(row, assignment)
    # The first column is the annotation category name...
    annotation_category_name = row.shift
    annotation_category = AnnotationCategory.new
    annotation_category.annotation_category_name = annotation_category_name
    annotation_category.assignment = assignment
    # If we can't save the AnnotationCategory, return false, bail out.
    return false unless annotation_category.save
    # And the rest of the row are the annotations
    row.each do |annotation_text_content|
      annotation_text = AnnotationText.new
      annotation_text.content = annotation_text_content
      annotation_text.annotation_category = annotation_category
      annotation_text.save
    end
    return true
  end
end
