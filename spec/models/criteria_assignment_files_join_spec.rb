describe CriteriaAssignmentFilesJoin do
  subject { create(:criteria_assignment_files_join) }

  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to belong_to(:assignment_file) }
  it { is_expected.to accept_nested_attributes_for(:criterion) }
  it { is_expected.to accept_nested_attributes_for(:assignment_file) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
end
