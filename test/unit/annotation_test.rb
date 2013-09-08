require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class AnnotationTest < ActiveSupport::TestCase

  context 'A good Annotation model' do

    should belong_to :submission_file
    should belong_to :annotation_text

    should validate_presence_of :submission_file
    should validate_presence_of :annotation_text
    should validate_presence_of :annotation_number

    should validate_numericality_of :annotation_text_id
    should validate_numericality_of :submission_file_id
    should validate_numericality_of :annotation_number

    should_not allow_value(-1).for(:annotation_text_id)
    should_not allow_value(-1).for(:submission_file_id)
    should_not allow_value(-1).for(:annotation_number)

    should allow_value('ImageAnnotation').for(:type)
    should allow_value('TextAnnotation').for(:type)
    should_not allow_value('OtherAnnotation').for(:type)

  end

end
