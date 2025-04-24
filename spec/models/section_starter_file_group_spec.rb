describe SectionStarterFileGroup do
  subject { create(:section_starter_file_group) }

  it { is_expected.to belong_to(:section) }
  it { is_expected.to belong_to(:starter_file_group) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  context 'more validations' do
    let(:section) { create(:section) }
    let(:ssfg1) { create(:section_starter_file_group, section: section) }
    let(:starter_file_group) { create(:starter_file_group, assignment: ssfg1.starter_file_group.assignment) }
    let(:ssfg2) { build(:section_starter_file_group, section: section) }
    let(:ssfg3) { build(:section_starter_file_group, section: section, starter_file_group: starter_file_group) }

    it 'is expected to validate uniqueness of section scoped by assessment' do
      expect(ssfg2).to be_valid
      expect(ssfg3).not_to be_valid
    end
  end
end
