describe GroupingStarterFileEntry do
  subject { create :grouping_starter_file_entry }
  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to belong_to(:starter_file_entry) }
  it { is_expected.to validate_presence_of(:grouping) }
  it { is_expected.to validate_presence_of(:starter_file_entry) }
  it { is_expected.to validate_uniqueness_of(:starter_file_entry_id).scoped_to(:grouping_id) }
end
