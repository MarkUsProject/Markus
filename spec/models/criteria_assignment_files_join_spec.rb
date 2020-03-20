describe CriteriaAssignmentFilesJoin do
  it { is_expected.to belong_to(:criterion) }
  it { is_expected.to belong_to(:assignment_file) }
  it { is_expected.to accept_nested_attributes_for(:criterion) }
  it { is_expected.to accept_nested_attributes_for(:assignment_file) }
end
