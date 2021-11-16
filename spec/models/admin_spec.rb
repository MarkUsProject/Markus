describe Admin do
  subject { create :admin }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }
end
