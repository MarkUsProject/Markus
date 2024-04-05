describe LtiUser do
  subject { create(:lti_user, user: student.user, lti_client: lti_client) }

  let(:student) { create(:student) }
  let(:lti_client) { create(:lti_client) }

  it { is_expected.to validate_uniqueness_of(:lti_user_id).scoped_to(:lti_client_id) }
end
