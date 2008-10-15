require 'test_helper'

class DescriptionTest < ActiveSupport::TestCase
  
  # Test that Description without name are not valid
  def test_no_name
    no_name = create_no_attr(:name);
    assert !no_name.valid?
  end
  
  # Test that Description without description are not valid
  def test_no_description
    no_description = create_no_attr(:description);
    assert !no_description.valid?
  end
  
  # Test that Description without token are not valid
  def test_no_token
    no_token = create_no_attr(:token);
    assert !no_token.valid?
  end
  
  # Test that Description without ntoken are not valid
  def test_no_ntoken
    no_ntoken = create_no_attr(:ntoken);
    assert !no_ntoken.valid?
  end
  
  # Test that Description without category_id are not valid
  def test_no_category_id
    no_category_id = create_no_attr(:category_id);
    assert !no_category_id.valid?
  end
  
  # Test that Description without assignment_id are not valid
  def test_no_assignment_id
    no_assignment_id = create_no_attr(:assignment_id);
    assert !no_assignment_id.valid?
  end
  
  
  #Category Id must be an integer greater or equal to 0
  def test_category_id_range
    category_id_range = create_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0 }

    bad.each do |id|

        category_id_range.category_id = id
        assert !category_id_range.valid?

    end
    
    category_id_range.category_id = 1
    assert category_id_range.valid?

  end

  #Assignment Id must be an integer greater or equal to 0
  def test_assignment_id_range
    assignment_id_range = create_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0 }

    bad.each do |id|

        assignment_id_range.assignment_id = id
        assert !assignment_id_range.valid?
    
    end

    assignment_id_range.assignment_id = 1
    assert assignment_id_range.valid?

  end


  #Test that Description assigned to non-existant Category is not valid
  def test_category_id_dne
    category_id_dne = create_no_attr(nil)
    category_id_dne.category = Category.new
    assert !category_id_dne.save
  end
  
  #Test that Description assigned to non-existant Assignment is not valid
  def test_assignment_id_dne
    assignment_id_dne = create_no_attr(nil)
    assignment_id_dne.assignment = Assignment.new
    assert !assignment_id_dne.save
  end
  
  
  # Helper method for test_validate_presence_of to create a annotation without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_description = { 
      :name => "desc1name",
      :description => "desc1desc", 
      :token => "d1", 
      :ntoken => 1,
      :category_id => 1,
      :assignment_id => 1
    }
    
    new_description.delete(attr) if attr
    Description.new(new_description)
  end
end
