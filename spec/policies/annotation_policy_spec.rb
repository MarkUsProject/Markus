describe AnnotationPolicy do
  let(:record) { create(:text_annotation) }
  let(:context) { { role: role, real_user: role.user } }

  shared_context 'a grader rule' do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      failed 'not assigned to the grouping' do
        let(:role) { create(:ta) }
      end
      succeed 'assigned to the grouping' do
        let(:role) { create(:ta) }
        before { create(:ta_membership, role: role, grouping: record.result.grouping) }
      end
      succeed 'not assigned but can manage submissions' do
        let(:role) { create(:ta, manage_submissions: true) }
      end
    end
  end

  describe_rule :manage? do
    include_context 'a grader rule'

    context 'role is a student' do
      let(:role) { create(:student) }

      failed 'not associated with a peer review'
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
    include_context 'a grader rule'

    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end
end
