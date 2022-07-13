describe 'Check Repo Permissions Standalone File' do
  # Disable transactional tests and clean up manually because we need models to be both saved AND committed to the
  # database in order for the standalone script to be able to see the changes (uncommitted changes are not visible).
  self.use_transactional_tests = false
  after do
    tables = ApplicationRecord.connection.tables - %w[schema_migrations ar_internal_metadata]
    ActiveRecord::Base.connection.truncate_tables(*tables)
  end

  let(:grouping) { create :grouping }
  let(:repo_path) { "#{grouping.course.name}/#{grouping.group.repo_name}.git" }
  let(:section) { create :section }

  context 'invalid args' do
    it 'should fail when there is an arg missing' do
      expect(script_success?('test', '')).to be_falsy
    end
    context 'when the repo path does not include the course name' do
      it 'should fail' do
        expect(script_success?('test', 'abc.git')).to be_falsy
      end
      it 'should report an error' do
        expect(exec_script('test', 'abc.git').second.strip).to eq 'repository path does not include course directory'
      end
    end
  end
  context 'role does not exist' do
    it 'should fail' do
      expect(script_success?('test', repo_path)).to be_falsy
    end
    it 'should report an error' do
      expect(exec_script('test', repo_path).second.strip).to eq 'user not found'
    end
  end
  context 'role is an Instructor' do
    let(:role) { create :instructor }
    context 'when the grouping exists' do
      it 'should succeed' do
        expect(script_success?(role.user_name, repo_path)).to be_truthy
      end
    end
    context 'when the grouping does not exist' do
      it 'should succeed' do
        # This allows git to report that the repo doesn't exist (a more useful error message than "not allowed")
        bad_repo_name = "#{grouping.course.name}/#{grouping.group.repo_name}123.git"
        expect(script_success?(role.user_name, bad_repo_name)).to be_truthy
      end
    end
  end
  context 'role is an AdminRole' do
    let(:role) { create :admin_role }
    context 'when the grouping exists' do
      it 'should succeed' do
        expect(script_success?(role.user_name, repo_path)).to be_truthy
      end
    end
    context 'when the grouping does not exist' do
      it 'should succeed' do
        # This allows git to report that the repo doesn't exist (a more useful error message than "not allowed")
        bad_repo_name = "#{grouping.course.name}/#{grouping.group.repo_name}123.git"
        expect(script_success?(role.user_name, bad_repo_name)).to be_truthy
      end
    end
  end
  context 'role is a Ta' do
    let(:role) { create :ta }
    context 'when the grouping exists' do
      context 'when the Ta is assigned as a grader' do
        before { create :ta_membership, role: role, grouping: grouping }
        context 'when the groups are anonymized' do
          before { grouping.assignment.update! anonymize_groups: true }
          it 'should fail' do
            expect(script_success?(role.user_name, repo_path)).to be_falsy
          end
        end
        context 'when the groups are not anonymized' do
          before { grouping.assignment.update! anonymize_groups: false }
          it 'should succeed' do
            expect(script_success?(role.user_name, repo_path)).to be_truthy
          end
        end
      end
      context 'when the Ta is not assigned as a grader' do
        context 'when the groups are not anonymized' do
          before { grouping.assignment.update! anonymize_groups: false }
          it 'should fail' do
            expect(script_success?(role.user_name, repo_path)).to be_falsy
          end
        end
      end
    end
    context 'when the grouping does not exist' do
      it 'should fail' do
        bad_repo_name = "#{grouping.course.name}/#{grouping.group.repo_name}123.git"
        expect(script_success?(role.user_name, bad_repo_name)).to be_falsy
      end
    end
  end
  context 'role is a Student' do
    let(:role) { create :student }
    context 'the grouping exists' do
      context 'vcs submit is true' do
        before { grouping.assignment.update! vcs_submit: true }
        context 'the student is an accepted member of the group' do
          before { create :accepted_student_membership, role: role, grouping: grouping }
          context 'the assignment is not hidden for everyone' do
            it 'should succeed' do
              expect(script_success?(role.user_name, repo_path)).to be_truthy
            end
          end
          context 'the assignment is hidden for everyone' do
            before { grouping.assignment.update! is_hidden: true }
            it 'should fail' do
              expect(script_success?(role.user_name, repo_path)).to be_falsy
            end
          end
          context 'the assignment is hidden for the section' do
            before do
              create :assessment_section_properties, assessment: grouping.assignment, section: section, is_hidden: true
              role.update! section_id: section.id
            end
            it 'should fail' do
              expect(script_success?(role.user_name, repo_path)).to be_falsy
            end
          end
          context 'the assignment is not hidden for the section' do
            before do
              create :assessment_section_properties, assessment: grouping.assignment, section: section, is_hidden: false
              role.update! section_id: section.id
            end
            it 'should succeed' do
              expect(script_success?(role.user_name, repo_path)).to be_truthy
            end
          end
          context 'the assessment is timed' do
            let(:due_date) { 1.minute.from_now }
            before do
              grouping.assignment.update! is_timed: true,
                                          due_date: due_date,
                                          start_time: 3.minutes.ago,
                                          duration: 1.minute
            end
            context 'the grouping has started the assessment' do
              before { grouping.update! start_time: 1.minute.ago }
              it 'should succeed' do
                expect(script_success?(role.user_name, repo_path)).to be_truthy
              end
            end
            context 'the grouping has not started the assessment' do
              context 'the due date has passed' do
                let(:due_date) { 1.second.ago }
                it 'should succeed' do
                  expect(script_success?(role.user_name, repo_path)).to be_truthy
                end
              end
              context 'the due date has not passed' do
                it 'should fail' do
                  expect(script_success?(role.user_name, repo_path)).to be_falsy
                end
              end
            end
          end
        end
        context 'the student is an inviter member of the group' do
          before { create :inviter_student_membership, role: role, grouping: grouping }
          it 'should succeed' do
            expect(script_success?(role.user_name, repo_path)).to be_truthy
          end
        end
        context 'the student is a pending member of the group' do
          before { create :student_membership, role: role, grouping: grouping }
          it 'should fail' do
            expect(script_success?(role.user_name, repo_path)).to be_falsy
          end
        end
        context 'the student is a rejected member of the group' do
          before { create :rejected_student_membership, role: role, grouping: grouping }
          it 'should fail' do
            expect(script_success?(role.user_name, repo_path)).to be_falsy
          end
        end
        context 'the student is not part of the group' do
          it 'should fail' do
            expect(script_success?(role.user_name, repo_path)).to be_falsy
          end
        end
      end
      context 'vcs submit is false' do
        before { grouping.assignment.update! vcs_submit: false }
        it 'should fail' do
          expect(script_success?(role.user_name, repo_path)).to be_falsy
        end
      end
    end
    context 'when the grouping does not exist' do
      it 'should fail' do
        bad_repo_name = "#{grouping.course.name}/#{grouping.group.repo_name}123.git"
        expect(script_success?(role.user_name, bad_repo_name)).to be_falsy
      end
    end
  end
end

def exec_script(user_name, repo_path)
  exec_path = Rails.root.join('bin/check_repo_permissions.rb')
  Open3.capture3({ RAILS_ENV: Rails.env }.stringify_keys, "#{exec_path} #{user_name} #{repo_path}")
end

def script_success?(user_name, repo_path)
  exec_script(user_name, repo_path).last.exitstatus.zero?
end
