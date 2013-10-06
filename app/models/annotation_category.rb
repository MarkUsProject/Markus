class AnnotationCategory < ActiveRecord::Base
  validates_presence_of :annotation_category_name
  has_many :annotation_texts, :dependent => :destroy
  belongs_to :assignment

  # Unique index for this validation is not require and can cause trouble
  # (ref. issue #191)
  validates_uniqueness_of :annotation_category_name, :scope => :assignment_id,
                          :message => 'is already taken'

  validates_presence_of :assignment_id
  validates_associated :assignment, :message => 'not strongly associated with assignment'

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,annotation_text,annotation_text,...
  def self.add_by_row(row, assignment, current_user)
    result = {}
    result[:annotation_upload_invalid_lines] = []
    # The first column is the annotation category name...
    annotation_category_name = row.shift
    annotation_category = assignment.annotation_categories.find_by_annotation_category_name(annotation_category_name)
    if annotation_category.nil?
      # Create a new annotation category
      annotation_category = AnnotationCategory.new
      annotation_category.annotation_category_name = annotation_category_name
      annotation_category.assignment = assignment
      annotation_category.save
    end

    row.each do |annotation_text_content|
      annotation_text = AnnotationText.new
      annotation_text.content = annotation_text_content
      annotation_text.annotation_category = annotation_category
      annotation_text.creator_id = current_user.id
      annotation_text.last_editor_id = current_user.id
      unless annotation_text.save
        # This line checks for the case where we are not given a category name
        # i.e ,123
        annotation_category_name = '' if annotation_category_name.nil?
        # If for some reason we are not able to update the category
        # send the respective error
        result[:annotation_upload_invalid_lines].push(annotation_category_name)
      end
    end
    return result
  end

  # Takes two arrays, one with annotation catogies names and one
  # with associated annotation texts
  # It is used with the Yaml format
  # Format :
  # annotation_category:
  # - annotation_text
  # - annotation_text
  # …
  def self.add_by_array(annotation_category_name, annotation_texts_content, assignment, current_user)
    result = {}
    result[:annotation_upload_invalid_lines] = []
    annotation_category = assignment.annotation_categories.find_by_annotation_category_name(annotation_category_name)
    if annotation_category.nil?
      # Create a new annotation category
      annotation_category = AnnotationCategory.new
      annotation_category.annotation_category_name = annotation_category_name
      annotation_category.assignment = assignment
      annotation_category.save!
    end
    annotation_texts_content.at(0).each do |text|
      annotation_text = AnnotationText.new
      annotation_text.content = text.to_s
      annotation_text.annotation_category = annotation_category
      annotation_text.creator_id = current_user.id
      annotation_text.last_editor_id = current_user.id
      unless annotation_text.save
        # This line checks for the case where we are not given a category name
        annotation_category_name = '' if annotation_category_name.nil?
        # If for some reason we are not able to update the category
        # send the respective error
        result[:annotation_upload_invalid_lines].push(annotation_category_name)
      end
    end
    return result
  end
end
