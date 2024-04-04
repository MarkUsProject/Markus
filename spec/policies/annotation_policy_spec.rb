describe AnnotationPolicy do
  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
      let(:context) { { role: role, real_user: role.user } }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
      let(:context) { { role: role, real_user: role.user } }
    end
    context 'role is a student' do
      let(:context) { { role: role, real_user: role.user } }
      let(:role) { create(:student) }
      failed 'not associated with a peer review' do
        let(:record) { create(:text_annotation) }
      end
      context 'associated with a peer review' do
        let(:assignment) { create(:assignment_with_peer_review) }
        let(:grouping) { create(:grouping, assignment: assignment) }
        let(:submission) { create(:submission, grouping: grouping) }
        let(:result) { create(:complete_result, submission: submission) }
        let(:record) { create(:text_annotation, result: result) }
        failed 'when the role is not a reviewer for the submission'
        succeed 'when the role is a reviewer' do
          before { allow(role).to receive(:is_reviewer_for?).and_return(true) }
        end
      end
    end
  end
  describe_rule :add_existing_annotation? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
      let(:context) { { role: role, real_user: role.user } }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
      let(:context) { { role: role, real_user: role.user } }
    end
  end
end
