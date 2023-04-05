describe GroupingPolicy do
  let(:context) { { role: role, real_user: role.user } }
  let(:record) { grouping }
  let(:grouping) { create :grouping }
  let(:role) { create :instructor }

  describe_rule :member? do
    let(:grouping) { create :grouping_with_inviter }
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'role is an ta' do
      let(:role) { create :ta }
    end
    context 'role is a student' do
      failed 'role is not a member' do
        let(:role) { create :student }
      end
      succeed 'role is a member' do
        let(:role) { grouping.inviter }
      end
    end
  end

  describe_rule :not_in_progress? do
    succeed 'test not in progress' do
      before { allow(grouping).to receive(:student_test_run_in_progress?).and_return false }
    end
    failed 'test in progress' do
      before { allow(grouping).to receive(:student_test_run_in_progress?).and_return true }
    end
  end

  describe_rule :tokens_available? do
    succeed 'when test tokens exist' do
      let(:grouping) { create :grouping, test_tokens: 1 }
    end
    succeed 'when there are unlimited tokens available' do
      let(:grouping) do
        create :grouping, assignment: create(:assignment, assignment_properties_attributes: { unlimited_tokens: true })
      end
    end
    failed 'when there are no tokens and tokens are limited' do
      let(:grouping) do
        create :grouping,
               assignment: create(:assignment, assignment_properties_attributes: { unlimited_tokens: false }),
               test_tokens: 0
      end
    end
  end

  describe_rule :invite_member? do
    let(:grouping) { create :grouping, assignment: assignment }
    let(:assignment) { create :assignment, assignment_properties_attributes: properties }
    succeed 'students form groups, has no extension, before collection date' do
      let(:properties) { { student_form_groups: true } }
    end
    failed 'students do not form groups, has no extension, before collection date' do
      let(:properties) { { student_form_groups: false } }
    end
    failed 'students form groups, has an extension, before collection date' do
      let(:properties) { { student_form_groups: true } }
      before { create :extension, grouping: grouping }
    end
    failed 'students form groups, has no extension, after collection date' do
      let(:properties) { { student_form_groups: true } }
      let(:assignment) { create :assignment, due_date: 1.day.ago, assignment_properties_attributes: properties }
    end
  end

  describe_rule :students_form_groups? do
    let(:grouping) { create :grouping, assignment: assignment }
    succeed 'invalid override is false' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { student_form_groups: true } }
    end
    failed 'invalid override is true' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { student_form_groups: false } }
    end
  end

  describe_rule :before_due_date? do
    succeed 'before collection date' do
      before { allow(grouping).to receive(:past_collection_date?).and_return false }
    end
    failed 'before collection date' do
      before { allow(grouping).to receive(:past_collection_date?).and_return true }
    end
  end

  describe_rule :disinvite_member? do
    let(:role) { create :student }
    let(:context) { { role: role, real_user: role.user, membership: membership } }
    succeed 'role is inviter and the membership status is pending' do
      let(:grouping) { create :grouping_with_inviter, inviter: role }
      let(:membership) { create :student_membership, grouping: grouping }
    end
    failed 'role is not the inviter and the membership status is pending' do
      let(:membership) { create :student_membership, grouping: grouping }
    end
    failed 'role is inviter and the membership status is not pending' do
      let(:grouping) { create :grouping_with_inviter, inviter: role }
      let(:membership) { create :accepted_student_membership, grouping: grouping }
    end
  end

  describe_rule :delete_rejected? do
    let(:role) { create :student }
    let(:context) { { role: role, real_user: role.user, membership: membership } }
    succeed 'role is inviter and the membership status is rejected' do
      let(:grouping) { create :grouping_with_inviter, inviter: role }
      let(:membership) { create :rejected_student_membership, grouping: grouping }
    end
    failed 'role is not the inviter and the membership status is rejected' do
      let(:membership) { create :rejected_student_membership, grouping: grouping }
    end
    failed 'role is inviter and the membership status is not rejected' do
      let(:grouping) { create :grouping_with_inviter, inviter: role }
      let(:membership) { create :student_membership, grouping: grouping }
    end
  end

  describe_rule :destroy? do
    succeed 'grouping is deletable by the user and there is no submission' do
      before { allow(grouping).to receive(:deletable_by?).and_return true }
    end
    failed 'grouping is not deletable by the user and there is no submission' do
      before { allow(grouping).to receive(:deletable_by?).and_return false }
    end
    failed 'grouping is deletable by the user but there is a submission' do
      before { allow(grouping).to receive(:deletable_by?).and_return true }
      let(:grouping) { create :grouping_with_inviter_and_submission }
    end
  end

  describe_rule :deletable_by? do
    succeed 'grouping is deletable by the user' do
      before { allow(grouping).to receive(:deletable_by?).and_return true }
    end
    failed 'grouping is not deletable by the user' do
      before { allow(grouping).to receive(:deletable_by?).and_return false }
    end
  end

  describe_rule :no_submission? do
    succeed 'grouping has no submission'
    failed 'grouping has a submission' do
      let(:grouping) { create :grouping_with_inviter_and_submission }
    end
  end

  describe_rule :no_extension? do
    succeed 'grouping has no extension'
    failed 'grouping has an extension' do
      before { create :extension, grouping: grouping }
    end
  end

  describe_rule :view_file_manager? do
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'role is a ta' do
      let(:role) { create :ta }
    end
    context 'role is a student' do
      let(:role) { create :student }
      let(:grouping) { create :grouping, assignment: assignment }
      succeed 'when the assignment is not scanned or a peer review or timed' do
        let(:assignment) { create :assignment }
      end
      failed 'when the assignment is scanned' do
        let(:assignment) { create :assignment_for_scanned_exam }
      end
      failed 'when the assignment is a peer review' do
        let(:assignment) { create :peer_review_assignment }
      end
      context 'when the assignment is timed' do
        let(:assignment) { create :timed_assignment }
        succeed 'and it has started' do
          let(:grouping) { create :grouping, assignment: assignment, start_time: 1.minute.ago }
        end
        failed 'and it has not started yet'
      end
    end
  end

  describe_rule :start_timed_assignment? do
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'role is a ta' do
      let(:role) { create :ta }
    end
    context 'role is a student' do
      let(:role) { create :student }
      let(:past_collection_date) { false }
      let(:past_assessment_start_time) { true }
      before do
        allow(grouping).to receive(:past_collection_date?).and_return past_collection_date
        allow(grouping).to receive(:past_assessment_start_time?).and_return past_assessment_start_time
      end
      succeed 'assignment has not started, not passed collection date, passed start time'
      failed 'assignment has been started' do
        let(:grouping) { create :grouping, start_time: 1.minute.ago }
      end
      failed 'passed collection date' do
        let(:past_collection_date) { true }
      end
      failed 'not passed assessment start time' do
        let(:past_assessment_start_time) { false }
      end
    end
  end

  describe_rule :download_starter_file? do
    failed 'role is an instructor' do
      let(:role) { create :instructor }
    end
    failed 'user is a ta' do
      let(:role) { create :ta }
    end
    context 'role is a student' do
      let(:role) { create :student }
      let(:grouping) { create :grouping, assignment: assignment }
      context 'when the assignment is not timed' do
        failed 'and is hidden' do
          let(:assignment) { create :assignment, is_hidden: true }
        end
        context 'and is visible' do
          succeed { let(:assignment) { create :assignment } }
          context 'and starter_files_after_due is false' do
            failed 'and grouping has passed collection time' do
              let(:assignment) do
                create :assignment,
                       due_date: 1.hour.ago,
                       assignment_properties_attributes: { starter_files_after_due: false }
              end
            end
            succeed 'and grouping is before the collection time' do
              let(:assignment) do
                create :assignment,
                       due_date: 1.hour.from_now,
                       assignment_properties_attributes: { starter_files_after_due: false }
              end
            end
          end
        end
      end
      context 'when the assignment is timed' do
        let(:assignment) { create :timed_assignment }
        succeed 'and it has started' do
          let(:grouping) { create :grouping, assignment: assignment, start_time: 1.minute.ago }
        end
        context 'and grouping has passed collection time' do
          succeed 'and starter_files_after_due is true' do
            let(:assignment) do
              create :timed_assignment,
                     due_date: 1.hour.ago,
                     assignment_properties_attributes: { starter_files_after_due: true }
            end
          end
          failed 'and starter_files_after_due is false' do
            let(:assignment) do
              create :timed_assignment,
                     due_date: 1.hour.ago,
                     assignment_properties_attributes: { starter_files_after_due: false }
            end
          end
        end
        context 'and grouping is before the collection time' do
          failed 'and starter_files_after_due is true' do
            let(:assignment) do
              create :timed_assignment,
                     due_date: 1.hour.from_now,
                     assignment_properties_attributes: { starter_files_after_due: true }
            end
          end
          failed 'and starter_files_after_due is false' do
            let(:assignment) do
              create :timed_assignment,
                     due_date: 1.hour.from_now,
                     assignment_properties_attributes: { starter_files_after_due: false }
            end
          end
        end
      end
    end
  end

  describe_rule :access_repo? do
    let(:assignment) { create :assignment, is_hidden: true }
    context 'role is a student' do
      let(:role) { create :student }
      let(:grouping) { create :grouping, assignment: assignment }
      context 'when the assignment is not timed' do
        succeed 'and version control submission is enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { vcs_submit: true } }
        end
        failed 'and version control submission is disabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { vcs_submit: false } }
        end
      end
      context 'when the assignment is timed and version control submission is enabled' do
        let(:assignment) { create :timed_assignment, assignment_properties_attributes: { vcs_submit: true } }
        succeed 'and the grouping has started' do
          let(:grouping) { create :grouping, assignment: assignment, start_time: 1.minute.ago }
        end
        failed 'and the grouping has not yet started' do
          let(:grouping) { create :grouping, assignment: assignment, start_time: nil }
        end
      end
    end
  end
end
