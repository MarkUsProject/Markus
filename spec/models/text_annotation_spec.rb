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
end
