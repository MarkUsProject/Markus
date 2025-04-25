describe HtmlAnnotation do
  subject { create(:html_annotation) }

  it { is_expected.to validate_presence_of(:start_node) }
  it { is_expected.to validate_presence_of(:end_node) }
  it { is_expected.to validate_presence_of(:start_offset) }
  it { is_expected.to validate_presence_of(:end_offset) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  describe '#get_data' do
    let(:annotation) { create(:html_annotation) }
    let(:extra_keys) { Set[:start_node, :end_node, :start_offset, :end_offset] }

    it_behaves_like 'gets annotation data'
  end
end
