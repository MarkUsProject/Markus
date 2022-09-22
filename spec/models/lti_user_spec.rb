describe LtiUser do
  let(:instructor) { create :instructor }
  describe 'uniqueness_validation' do
    let(:lti_user) { create :lti_user, user: instructor.user }
    it do
      expect(lti_user).to validate_uniqueness_of(:lti_user_id).scoped_to(:lti_client)
    end
  end
end
