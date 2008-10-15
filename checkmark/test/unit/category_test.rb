require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  
  
  # Test that Category without name are not valid
  def test_no_name
    no_name = create_no_attr(:name);
    assert !no_name.valid?
  end
  
  # Test that Category without token are not valid
  def test_no_token
    no_token = create_no_attr(:token);
    assert !no_token.valid?
  end
  
  # Test that Category without ntoken are not valid
  def test_no_ntoken
    no_ntoken = create_no_attr(:ntoken);
    assert !no_ntoken.valid?
  end
  
  
  # Helper method for test_validate_presence_of to create a category without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_category = { 
      :name => "category1",
      :token => "c1", 
      :ntoken => 1,
    }
    
    new_category.delete(attr) if attr
    Category.new(new_category)
  end
end
