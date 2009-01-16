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

end
