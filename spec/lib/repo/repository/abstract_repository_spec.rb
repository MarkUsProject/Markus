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

  describe '.get_student_permissions_bulk' do
    let(:course) { create(:course) }

    def visibility_hash_for(*assignments)
      assignments.to_h { |a| [a.id, Hash.new { true }] }
    end

    describe 'returns student permissions for valid groupings' do
      it 'includes accepted and inviter students' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(result[repo_path]).to eq([student.user_name])
      end

      it 'excludes pending and rejected students' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true })
        inviter = create(:student, course: course)
        pending_student = create(:student, course: course)
        rejected_student = create(:student, course: course)

        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: inviter)
        create(:student_membership, grouping: grouping, role: pending_student,
                                    membership_status: StudentMembership::STATUSES[:pending])
        create(:rejected_student_membership, grouping: grouping, role: rejected_student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(result[repo_path]).to eq([inviter.user_name])
      end
    end

    describe 'filters out invalid groupings' do
      it 'excludes groupings that are not instructor_approved and below group_min' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true,
                                                                             group_min: 2, group_max: 2 })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: false)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        expect(result.keys).to be_empty
      end

      it 'includes groupings that are instructor_approved even if below group_min' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true,
                                                                             group_min: 2, group_max: 2 })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(result[repo_path]).to eq([student.user_name])
      end
    end

    describe 'filters by assignment and course properties' do
      it 'excludes assignments with vcs_submit disabled' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: false })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        expect(result.keys).to be_empty
      end

      it 'excludes groupings from hidden courses' do
        hidden_course = create(:course, is_hidden: true)
        assignment = create(:assignment, course: hidden_course,
                                         assignment_properties_attributes: { vcs_submit: true })
        student = create(:student, course: hidden_course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        expect(result.keys).to be_empty
      end

      it 'excludes hidden students' do
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true })
        visible_student = create(:student, course: course, hidden: false)
        hidden_student = create(:student, course: course, hidden: true)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: visible_student)
        create(:accepted_student_membership, grouping: grouping, role: hidden_student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(result[repo_path]).to eq([visible_student.user_name])
      end
    end

    describe 'timed assignment handling' do
      it 'includes timed assignments that have started' do
        assignment = create(:assignment, course: course, due_date: 1.day.from_now,
                                         assignment_properties_attributes: { vcs_submit: true, is_timed: true,
                                                                             duration: 2.hours, start_time: 1.day.ago })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true, start_time: 1.hour.ago)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(result[repo_path]).to eq([student.user_name])
      end

      it 'excludes timed assignments that have not started and are not past due' do
        assignment = create(:assignment, course: course, due_date: 1.day.from_now,
                                         assignment_properties_attributes: { vcs_submit: true, is_timed: true,
                                                                             duration: 2.hours, start_time: 1.day.ago })
        student = create(:student, course: course)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true, start_time: nil)
        create(:inviter_student_membership, grouping: grouping, role: student)

        result = Repository.get_class.get_student_permissions_bulk(visibility_hash_for(assignment))

        expect(result.keys).to be_empty
      end
    end

    describe 'visibility based on inviter section' do
      it 'uses the inviter section to determine visibility' do
        section = create(:section, course: course)
        assignment = create(:assignment, course: course,
                                         assignment_properties_attributes: { vcs_submit: true })
        student = create(:student, course: course, section: section)
        grouping = create(:grouping, assignment: assignment, instructor_approved: true)
        create(:inviter_student_membership, grouping: grouping, role: student)

        visible_result = Repository.get_class.get_student_permissions_bulk({ assignment.id => { section.id => true } })
        hidden_result = Repository.get_class.get_student_permissions_bulk({ assignment.id => { section.id => false } })

        repo_path = File.join(course.name, grouping.group.repo_name)
        expect(visible_result[repo_path]).to eq([student.user_name])
        expect(hidden_result.keys).to be_empty
      end
    end

    describe 'shared repo across assignments' do
      it 'processes each repo only once when shared across multiple assignments' do
        group = create(:group, course: course)

        assignment1 = create(:assignment, course: course, due_date: 1.day.from_now,
                                          assignment_properties_attributes: { vcs_submit: true })
        assignment2 = create(:assignment, course: course, due_date: 2.days.from_now,
                                          assignment_properties_attributes: { vcs_submit: true })

        student1 = create(:student, course: course)
        student2 = create(:student, course: course)

        grouping1 = create(:grouping, assignment: assignment1, group: group, instructor_approved: true)
        grouping2 = create(:grouping, assignment: assignment2, group: group, instructor_approved: true)

        create(:inviter_student_membership, grouping: grouping1, role: student1)
        create(:inviter_student_membership, grouping: grouping2, role: student2)

        result = Repository.get_class.get_student_permissions_bulk(
          visibility_hash_for(assignment1, assignment2)
        )

        repo_path = File.join(course.name, group.repo_name)
        # Repo should only appear once with one set of permissions
        expect(result.keys.count { |k| k == repo_path }).to eq(1)
        expect(result[repo_path].size).to eq(1)
      end
    end
  end
end
