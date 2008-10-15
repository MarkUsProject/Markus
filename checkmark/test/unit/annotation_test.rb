require File.dirname(__FILE__) + '/../test_helper'

class AnnotationTest < ActiveSupport::TestCase
  
  # Test that Annotation without pos_start are not valid
  def test_no_pos_start
    no_pos_start = create_no_attr(:pos_start);
    assert !no_pos_start.valid?
  end
  
  # Test that Annotation without pos_end are not valid
  def test_no_pos_end
    no_pos_end = create_no_attr(:pos_end);
    assert !no_pos_end.valid?
  end
  
  # Test that Annotation without line_start are not valid
  def test_no_line_start
    no_line_start = create_no_attr(:line_start);
    assert !no_line_start.valid?
  end
  
  # Test that Annotation without line_end are not valid
  def test_no_line_end
    no_line_end = create_no_attr(:line_end);
    assert !no_line_end.valid?
  end

  # Test that valid Annotation
  def test_no_line_end
    valid_annotation = create_no_attr(:nil);
    assert valid_annotation.valid?
  end
  
  #Description Id must be an integer greater or equal to 0
  def test_description_id_range
    description_id_range = create_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0}

    bad.each do |id|

        description_id_range.description_id = id
        assert !description_id_range.valid?

    end
    
    description_id_range.description_id = 1
    assert description_id_range.valid?

  end

  #Description Id must be an integer greater or equal to 0
  def test_assignmentfile_id_range
    assignmentfile_id_range = create_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0}

    bad.each do |id|

        assignmentfile_id_range.assignmentfile_id = id
        assert !assignmentfile_id_range.valid?

    end

    assignmentfile_id_range.assignmentfile_id = 1
    assert assignmentfile_id_range.valid?

  end


  #Test that Annotation assigned to non-existant Description is not valid
  def test_description_id_dne
    description_id_dne = create_no_attr(nil)
    description_id_dne.description = Description.new
    assert !description_id_dne.save
  end
  
  #Test that Annotation assigned to non-existant File is not valid

  def test_assignmentfile_id_dne
    assignmentfile_id_dne = create_no_attr(nil)
    assignmentfile_id_dne.assignment_file = AssignmentFile.new
    assert !assignmentfile_id_dne.save
  end
  
  
  # Helper method for test_validate_presence_of to create a annotation without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_annotation = { 
      :pos_start => 1,
      :pos_end => 10, 
      :line_start => 1, 
      :line_end => 10,
      :description_id => 1,
      :assignmentfile_id => 1
    }
    
    new_annotation.delete(attr) if attr
    Annotation.new(new_annotation)
  end
end
