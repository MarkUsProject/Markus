require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class ImageAnnotationTest < ActiveSupport::TestCase

  should validate_presence_of :x1
  should validate_presence_of :x2
  should validate_presence_of :y1
  should validate_presence_of :y2
  should validate_numericality_of :x1
  should validate_numericality_of :x2
  should validate_numericality_of :y1
  should validate_numericality_of :y2

  def test_extract_coords
    basic_annot = ImageAnnotation.make({:x1 => 0, :x2 => 10, :y1 => 0, :y2 => 10})
    negative_annot = ImageAnnotation.make({:x1 => -1, :x2 => 3, :y1 => -2, :y2 => 5})
    spaces_annot = ImageAnnotation.make({:x1 => -1, :x2 => 3, :y1 => 123, :y2 => 5})

    assert_equal basic_annot.extract_coords, {:id => basic_annot.annotation_text_id, :x_range => {:start => 0, :end => 10}, :y_range => {:start => 0, :end => 10}}
    assert_equal negative_annot.extract_coords, {:id => negative_annot.annotation_text_id, :x_range => {:start => -1, :end => 3}, :y_range => {:start => -2, :end => 5}}
    assert_equal spaces_annot.extract_coords, {:id => spaces_annot.annotation_text_id, :x_range => {:start => -1, :end => 3}, :y_range => {:start => 5, :end => 123}}
  end

end
