describe AnnotationPolicy do
  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:context) { { user: create(:admin) } }
    end
    succeed 'user is a ta' do
      let(:context) { { user: create(:ta) } }
    end
    context 'user is a student' do
      let(:context) { { user: user } }
      let(:user) { create :student }
      failed 'not associated with a peer review' do
        let(:record) { create :text_annotation }
      end
      context 'associated with a peer review' do
        let(:assignment) { create :assignment_with_peer_review }
        let(:grouping) { create(:grouping, assignment: assignment) }
        let(:submission) { create(:submission, grouping: grouping) }
        let(:result) { create :complete_result, submission: submission }
        let(:record) { create :text_annotation, result: result }
        failed 'when the user is not a reviewer for the submission'
        succeed 'when the user is a reviewer' do
          before { allow(user).to receive(:is_reviewer_for?).and_return(true) }
        end
      end
    end
  end
  describe_rule :add_existing_annotation? do
    succeed 'user is an admin' do
      let(:context) { { user: create(:admin) } }
    end
    succeed 'user is a ta' do
      let(:context) { { user: create(:ta) } }
    end
  end
end
