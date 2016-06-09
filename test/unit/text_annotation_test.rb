require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'


class TextAnnotationTest < ActiveSupport::TestCase

  context 'A valid TextAnnotation model' do

    should validate_presence_of :line_start
    should validate_presence_of :line_end

    should allow_value(10).for(:line_start)
    should allow_value(10).for(:line_end)

    #TODO Change Model.
    #We should not allow negative values vor lines
    #should_not allow_value(-1).for(:line_start)
    #should_not allow_value(-1).for(:line_end)

  end

  context 'JavaScript functions' do

    setup do
      @ta = Ta.make
      @textannotation = TextAnnotation.make({creator: @ta})
    end

    should 'render annotation_list_link_partial' do
      assert @textannotation.annotation_list_link_partial,
             '/annotations/text_annotation_list_link'
    end

  end

end
