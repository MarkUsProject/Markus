describe Instructor do
  subject { create(:instructor) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }

  describe 'An instructor' do
    it 'cannot be assigned to an admin user' do
      expect(build(:instructor, user: create(:admin_user))).not_to be_valid
    end

    it 'cannot be assigned to an autotest user' do
      expect(build(:instructor, user: create(:autotest_user))).not_to be_valid
    end
  end
end
