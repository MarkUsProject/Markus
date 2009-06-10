require 'test_helper'

class AnnotationCategoryTest < ActiveSupport::TestCase

  # Test that an Annotations Category without name are not valid
  def test_no_name
    no_name = create_no_attr(:name);
    assert !no_name.valid?
  end
    
  # Helper method for test_validate_presence_of to create a category without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_annotation_category = { 
      :name => "annotationcategory1",
    }
    
    new_annotation_category.delete(attr) if attr
    AnnotationCategory.new(new_annotation_category)
  end

  # test the presence of an assignment id
  def test_presence_of_assignment_id
    annotation = AnnotationCategory.new
    annotation.annotation_category_name = "essai"
    assert !annotation.save, "Annotation category saved without an
    assignment id"
  end

  def test_presence_of_name
    annotation = AnnotationCategory.new
    annotation.assignment_id = 1
    assert !annotation.save, "Annotation category saved without an
    name"
  end

  def test_save_when_everything_is_OK
    annotation = AnnotationCategory.new
    annotation.assignment_id = 1
    annotation.annotation_category_name = "test"
    assert annotation.save, "Annotation category NOT saved"
  end


end
