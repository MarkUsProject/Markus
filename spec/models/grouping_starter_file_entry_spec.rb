describe GroupingStarterFileEntry do
  subject { create(:grouping_starter_file_entry) }

  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to belong_to(:starter_file_entry) }
  it { is_expected.to validate_uniqueness_of(:starter_file_entry_id).scoped_to(:grouping_id) }
  it { is_expected.to have_one(:course) }

  it 'should not allow associations to belong to different assignments' do
    subject.grouping = create(:grouping)
    expect(subject).not_to be_valid
  end
end
