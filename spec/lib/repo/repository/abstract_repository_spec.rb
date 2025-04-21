describe Repository::AbstractRepository do
  context 'update repo permissions' do
    before { Thread.current[:requested?] = false } # simulates each test happening in its own thread

    context 'repository permissions should be updated' do
      context 'exactly once' do
        it 'for a single update' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Repository.get_class.update_permissions
        end

        it 'at the end of a batch update' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Repository.get_class.update_permissions_after {} # rubocop:disable Lint/EmptyBlock
        end

        it 'at the end of a batch update only if requested' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Repository.get_class.update_permissions_after(only_on_request: true) do
            Repository.get_class.update_permissions
          end
        end

        it 'at the end of the most outer nested batch update' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Repository.get_class.update_permissions_after do
            Repository.get_class.update_permissions_after {} # rubocop:disable Lint/EmptyBlock
          end
        end
      end

      context 'multiple times' do
        it 'for multiple updates made by the same thread' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).twice
          Repository.get_class.update_permissions
          Repository.get_class.update_permissions
        end
      end
    end

    context 'repository permissions should not be updated' do
      it 'when not in authoritative mode' do
        allow(Settings.repository).to receive(:is_repository_admin).and_return(false)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        Repository.get_class.update_permissions
      end

      it 'at the end of a batch update if not requested' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        Repository.get_class.update_permissions_after(only_on_request: true) {} # rubocop:disable Lint/EmptyBlock
      end

      it 'at the end of the most outer nested batch update only if requested' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        Repository.get_class.update_permissions_after(only_on_request: true) do
          Repository.get_class.update_permissions_after(only_on_request: true) {} # rubocop:disable Lint/EmptyBlock
        end
      end
    end
  end

  describe '#visibility_hash' do
    let(:assessment_section_property) do
      create(:assessment_section_properties,
             is_hidden: true,
             assessment: assignments.first,
             section: sections.first)
    end
    let(:assessment_section_property2) do
      create(:assessment_section_properties,
             is_hidden: false,
             assessment: assignments.first,
             section: sections.second)
    end
    let(:assessment_section_property3) do
      create(:assessment_section_properties,
             is_hidden: nil,
             assessment: assignments.second,
             section: sections.first)
    end
    let(:assessment_section_property4) do
      create(:assessment_section_properties,
             is_hidden: nil,
             assessment: assignments.second,
             section: sections.second)
    end

    context 'when all assignments are hidden' do
      let!(:assignments) { create_list(:assignment, 2, is_hidden: true) }
      let!(:sections) { create_list(:section, 2) }

      shared_examples 'default tests' do
        it 'should return false for all sections' do
          assignments.each do |assignment|
            sections.each do |section|
              expect(Repository.get_class.visibility_hash[assignment.id][section.id]).to be false
            end
          end
        end

        it 'should return false for no section' do
          assignments.each do |assignment|
            expect(Repository.get_class.visibility_hash[assignment.id][nil]).to be false
          end
        end
      end

      it_behaves_like 'default tests'
      context 'when assignment properties are set with nil is_hidden value' do
        before { [assessment_section_property3, assessment_section_property4] }

        it_behaves_like 'default tests'
      end

      context 'when assignment properties are set with true is_hidden value' do
        before { [assessment_section_property] }

        it_behaves_like 'default tests'
      end

      context 'when assignment properties are set with false is_hidden value' do
        before { [assessment_section_property2] }

        it 'should return true for section 2' do
          expect(Repository.get_class.visibility_hash[assignments.first.id][sections.second.id]).to be true
        end
      end
    end

    context 'when no assignments are hidden' do
      let!(:assignments) { create_list(:assignment, 2, is_hidden: false) }
      let!(:sections) { create_list(:section, 2) }

      shared_examples 'default tests' do
        it 'should return false for all sections' do
          assignments.each do |assignment|
            sections.each do |section|
              expect(Repository.get_class.visibility_hash[assignment.id][section.id]).to be true
            end
          end
        end

        it 'should return true for no section' do
          assignments.each do |assignment|
            expect(Repository.get_class.visibility_hash[assignment.id][nil]).to be true
          end
        end
      end

      it_behaves_like 'default tests'
      context 'when assignment properties are set with nil is_hidden value' do
        before { [assessment_section_property3, assessment_section_property4] }

        it_behaves_like 'default tests'
      end

      context 'when assignment properties are set with true is_hidden value' do
        before { [assessment_section_property2] }

        it_behaves_like 'default tests'
      end

      context 'when assignment properties are set with false is_hidden value' do
        before { [assessment_section_property] }

        it 'should return false for section 1' do
          expect(Repository.get_class.visibility_hash[assignments.first.id][sections.first.id]).to be false
        end
      end
    end

    context 'when one assignment is hidden' do
      let!(:hidden_assignment) { create(:assignment, is_hidden: true) }
      let!(:shown_assignment) { create(:assignment, is_hidden: false) }
      let!(:sections) { create_list(:section, 2) }

      it 'should return false for all sections' do
        sections.each do |section|
          expect(Repository.get_class.visibility_hash[shown_assignment.id][section.id]).to be true
          expect(Repository.get_class.visibility_hash[hidden_assignment.id][section.id]).to be false
        end
      end

      it 'should indicate which assignment is hidden' do
        expect(Repository.get_class.visibility_hash[shown_assignment.id][nil]).to be true
        expect(Repository.get_class.visibility_hash[hidden_assignment.id][nil]).to be false
      end
    end
  end

  describe '#get_repo_auth_records' do
    let(:assignment1) { create(:assignment, assignment_properties_attributes: { vcs_submit: false }) }
    let(:assignment2) { create(:assignment, assignment_properties_attributes: { vcs_submit: false }) }

    before do
      create_list(:grouping_with_inviter, 3, assignment: assignment1)
      create_list(:grouping_with_inviter, 3, assignment: assignment2)
    end

    context 'all assignments with vcs_submit == false' do
      it 'should be empty' do
        expect(Repository.get_class.get_repo_auth_records).to be_empty
      end
    end

    context 'one assignment with vcs_submit == true' do
      let(:assignment1) { create(:assignment, assignment_properties_attributes: { vcs_submit: true }) }

      it 'should only contain valid memberships' do
        ids = assignment1.groupings.map { |g| g.inviter.id }
        expect(Repository.get_class.get_repo_auth_records.pluck('roles.id')).to match_array(ids)
      end

      context 'when there is a pending membership' do
        before { create(:student_membership, grouping: assignment1.groupings.first) }

        it 'should not contain the pending membership' do
          ids = assignment1.groupings.map { |g| g.inviter.id }
          expect(Repository.get_class.get_repo_auth_records.pluck('roles.id')).to match_array(ids)
        end
      end

      context 'when the assignment belongs to a hidden course' do
        let(:assignment1) do
          course = create(:course, is_hidden: true)
          create(:assignment, assignment_properties_attributes: { vcs_submit: true }, course: course)
        end

        it 'should be empty' do
          expect(Repository.get_class.get_repo_auth_records).to be_empty
        end
      end
    end

    context 'both assignments with vcs_submit == true and is_timed == true' do
      let(:assignment1) { create(:timed_assignment, assignment_properties_attributes: { vcs_submit: true }) }
      let(:assignment2) { create(:timed_assignment, assignment_properties_attributes: { vcs_submit: true }) }

      it 'should be empty' do
        expect(Repository.get_class.get_repo_auth_records).to be_empty
      end

      context 'when one grouping has started their assignment' do
        let!(:grouping) do
          g = assignment1.groupings.first
          g.update!(start_time: 1.hour.ago)
          g.reload
        end

        it 'should contain only the members of that group' do
          expect(Repository.get_class.get_repo_auth_records.pluck('roles.id')).to contain_exactly(grouping.inviter.id)
        end

        context 'when the timed assessment due date has ended' do
          let(:assignment1) do
            create(:timed_assignment, assignment_properties_attributes: { vcs_submit: true }, due_date: 1.minute.ago)
          end

          it 'should contain all members of all groups' do
            inviter_ids = assignment1.groupings.map { |g| g.inviter.id }
            expect(Repository.get_class.get_repo_auth_records.pluck('roles.id')).to match_array(inviter_ids)
          end
        end
      end
    end
  end

  describe '#get_all_permissions' do
    let!(:course) { create(:course) }
    let(:assignment) { create(:assignment_with_criteria_and_results_and_tas) }

    context 'instructor permissions' do
      let!(:instructor) { create(:instructor, hidden: false) }

      it 'correctly retrieves permissions for instructors' do
        instructor2 = create(:instructor)
        accessible_path = File.join(course.name, '*')
        expect(Repository.get_class.get_all_permissions[accessible_path]).to(
          match_array([instructor.user_name, instructor2.user_name])
        )
      end

      it 'does not retrieve permissions for inactive instructors' do
        create(:instructor, hidden: true)
        accessible_path = File.join(course.name, '*')
        expect(Repository.get_class.get_all_permissions[accessible_path]).to(
          match_array([instructor.user_name])
        )
      end
    end

    context 'ta permissions' do
      let(:received_grader_permissions) do
        grader_info = {}
        permissions = Repository.get_class.get_all_permissions
        assignment.ta_memberships.each do |membership|
          repo_path = File.join(course.name, membership.grouping.group.repo_name)
          grader_info[repo_path] = permissions[repo_path] if permissions[repo_path].present?
        end
        grader_info
      end

      it 'correctly retrieves permissions for graders' do
        expected_grader_permissions = {}
        assignment.ta_memberships.each do |membership|
          repo_path = File.join(course.name, membership.grouping.group.repo_name)
          expected_grader_permissions[repo_path] = [] if expected_grader_permissions[repo_path].blank?
          expected_grader_permissions[repo_path] << membership.role.user_name
        end
        expect(received_grader_permissions).to eq(expected_grader_permissions)
      end

      it 'does not retrieve permissions for inactive graders' do
        assignment.ta_memberships.each { |membership| membership.role.update(hidden: true) }
        expect(received_grader_permissions).to eq({})
      end
    end

    context 'student permissions' do
      let(:assignment) do
        create(:assignment_with_criteria_and_results, assignment_properties_attributes: { vcs_submit: true })
      end

      let(:received_student_permissions) do
        student_info = {}
        permissions = Repository.get_class.get_all_permissions
        assignment.valid_groupings.each do |valid_grouping|
          repo_name = valid_grouping.group.repository_relative_path
          student_info[repo_name] = permissions[repo_name] if permissions[repo_name].present?
        end
        student_info
      end

      it 'correctly retrieves permissions for students' do
        expected_student_permissions = {}
        assignment.valid_groupings.each do |valid_grouping|
          repo_name = valid_grouping.group.repository_relative_path
          expected_student_permissions[repo_name] = valid_grouping.accepted_students
                                                                  .where('roles.hidden': false).map(&:user_name)
        end
        expect(received_student_permissions).to eq(expected_student_permissions)
      end

      it 'does not retrieve permissions for inactive students' do
        assignment.student_memberships.each { |membership| membership.role.update(hidden: true) }
        expect(received_student_permissions).to eq({})
      end
    end
  end
end
