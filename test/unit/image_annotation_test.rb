require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
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

  context 'Extract Coords' do

    setup do
      @basic_annot = ImageAnnotation.make(
        {:x1 => 0, :x2 => 10, :y1 => 0, :y2 => 10})
      @negative_annot = ImageAnnotation.make(
        {:x1 => -1, :x2 => 3, :y1 => -2, :y2 => 5})
      @spaces_annot = ImageAnnotation.make(
        {:x1 => -1, :x2 => 3, :y1 => 123, :y2 => 5})
      @annotation = ImageAnnotation.make
    end

    should 'put extract Coords' do
      assert_equal @basic_annot.extract_coords,
        {:id => @basic_annot.annotation_text_id,
          :x_range => {:start => 0, :end => 10},
          :y_range => {:start => 0, :end => 10}}
      assert_equal @negative_annot.extract_coords,
        {:id => @negative_annot.annotation_text_id,
          :x_range => {:start => -1, :end => 3},
          :y_range => {:start => -2, :end => 5}}
      assert_equal @spaces_annot.extract_coords,
        {:id => @spaces_annot.annotation_text_id,
          :x_range => {:start => -1, :end => 3},
          :y_range => {:start => 5, :end => 123}}
    end

    should 'render add_annotation_js_string' do
      assert @annotation.add_annotation_js_string,
        "add_to_annotation_grid('#{@annotation.extract_coords.to_json()}')"
    end

    should 'render remove_annotation_js_string' do
      assert @annotation.remove_annotation_js_string,
        "remove_annotation(null, null, #{@annotation.annotation_text.id});"
    end

    should 'render partial' do
      assert @annotation.annotation_list_link_partial,
        '/annotations/image_annotation_list_link'
    end

  end

end
