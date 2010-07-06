require File.dirname(__FILE__) + '/../test_helper'

class AnnotationTest < ActiveSupport::TestCase
  fixtures :all
  # Test that Annotation without line_start are not valid
  def test_no_line_start
    text_no_line_start = create_text_no_attr(:line_start);
    assert !text_no_line_start.valid?
  end

  # Test that Annotation without line_end are not valid
  def test_no_line_end
    text_no_line_start = create_text_no_attr(:line_end);
    assert !text_no_line_start.valid?
  end

  #Description Id must be an integer greater or equal to 0
  def test_annotation_text_id_range
    annotation_text_id_range = create_text_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0}

    bad.each do |id|

        annotation_text_id_range.annotation_text_id = id
        assert !annotation_text_id_range.valid?

    end

  end

  #Description Id must be an integer greater or equal to 0
  def test_submissionfile_id_range
    submissionfile_id_range = create_text_no_attr(nil)

    bad = %w{ 'string', -0.1, -1, 0}

    bad.each do |id|

        submissionfile_id_range.submission_file_id = id
        assert !submissionfile_id_range.valid?

    end

  end


  #Test that Annotation assigned to non-existant Description is not valid
  def test_annotation_text_id_dne
    annotation_text_id_dne = create_text_no_attr(nil)
    annotation_text_id_dne.annotation_text = AnnotationText.new
    assert !annotation_text_id_dne.save
  end

  #Test that Annotation assigned to non-existant File is not valid

  def test_submission_file_id_dne
    submission_file_id_dne = create_text_no_attr(nil)
    submission_file_id_dne.submission_file = SubmissionFile.new
    assert !submission_file_id_dne.save
  end


  # Helper method for test_validate_presence_of to create a annotation without
  # the specified attribute. if attr == nil then all attributes are included
  def create_text_no_attr(attr)
    new_annotation = {
      :line_start => 1,
      :line_end => 10,
      :annotation_text_id => 1,
      :submission_file_id => 1
    }
    new_annotation.delete(attr) if attr
    TextAnnotation.new(new_annotation)
  end
end
