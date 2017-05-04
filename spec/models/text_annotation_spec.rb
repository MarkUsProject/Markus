require 'spec_helper'

describe TextAnnotation do
  context 'A valid TextAnnotation model' do
    it { is_expected.to validate_presence_of(:line_start) }
    it { is_expected.to validate_presence_of(:line_end) }
    it { is_expected.to allow_value(10).for(:line_start) }
    it { is_expected.to allow_value(10).for(:line_end) }

    #TODO Change Model.
    #We should not allow negative values vor lines
    #should_not allow_value(-1).for(:line_start)
    #should_not allow_value(-1).for(:line_end)
  end

  context 'JavaScript functions' do
    before(:each)  do
      @ta = Ta.create()
      @textannotation = TextAnnotation.create({creator: @ta})
    end
    it 'render annotation_list_link_partial' do
      expect(@textannotation.annotation_list_link_partial).to eq ('/annotations/text_annotation_list_link')
    end
  end
end
