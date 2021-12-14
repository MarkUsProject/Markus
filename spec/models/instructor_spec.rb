describe Instructor do
  subject { create :instructor }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }
end
