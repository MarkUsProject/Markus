describe 'Check Repo Permissions Function' do
  let(:grouping) { create(:grouping) }
  let(:course_name) { grouping.course.name }
  let(:repo_name) { grouping.group.repo_name }
  let(:section) { create(:section) }

  context 'role does not exist' do
    let(:role) { build(:instructor) }

    it 'should fail' do
      expect(script_success?).to be_falsy
    end
  end

  context 'role is an Instructor' do
    let(:role) { create(:instructor) }

    context 'when the grouping exists' do
      it 'should succeed' do
        expect(script_success?).to be_truthy
      end
    end

    context 'when the grouping does not exist' do
      let(:course_name) { role.course.name }
      let(:grouping) { build(:grouping) }

      it 'should succeed' do
        # This allows git to report that the repo doesn't exist (a more useful error message than "not allowed")
        expect(script_success?).to be_truthy
      end
    end

    context 'when requested course is different' do
      let(:course) { create(:course) }
      let(:assignment) { create(:assignment, course: course) }
      let(:grouping) { create(:grouping, assignment: assignment) }

      it 'should fail' do
        expect(script_success?).to be_falsy
      end
    end

    context 'when requested course does not exist' do
      let(:course_name) { build(:course).name }

      it 'should fail' do
        expect(script_success?).to be_falsy
      end
    end

    context 'when the instructor is hidden' do
      let(:role) { create(:instructor, hidden: true) }

      it 'should fail' do
        expect(script_success?).to be_falsy
      end
    end
  end

  context 'role is an AdminRole' do
    let(:role) { create(:admin_role) }

    context 'when the grouping exists' do
      it 'should succeed' do
        expect(script_success?).to be_truthy
      end
    end

    context 'when the grouping does not exist' do
      let(:course_name) { role.course.name }
      let(:grouping) { build(:grouping) }

      it 'should succeed' do
        # This allows git to report that the repo doesn't exist (a more useful error message than "not allowed")
        expect(script_success?).to be_truthy
      end
    end
  end

  context 'role is a Ta' do
    let(:role) { create(:ta) }

    context 'when the grouping exists' do
      context 'when the Ta is assigned as a grader' do
        before { create(:ta_membership, role: role, grouping: grouping) }

        context 'when the groups are anonymized' do
          before { grouping.assignment.update! anonymize_groups: true }

          it 'should fail' do
            expect(script_success?).to be_falsy
          end
        end

        context 'when the groups are not anonymized' do
          before { grouping.assignment.update! anonymize_groups: false }

          it 'should succeed' do
            expect(script_success?).to be_truthy
          end

          context 'when the ta is hidden' do
            before { role.update!(hidden: true) }

            it 'should fail' do
              expect(script_success?).to be_falsy
            end
          end
        end
      end

      context 'when the Ta is not assigned as a grader' do
        context 'when the groups are not anonymized' do
          before { grouping.assignment.update! anonymize_groups: false }

          it 'should fail' do
            expect(script_success?).to be_falsy
          end
        end
      end
    end

    context 'when the grouping does not exist' do
      let(:course_name) { role.course.name }
      let(:grouping) { build(:grouping) }

      it 'should fail' do
        expect(script_success?).to be_falsy
      end
    end
  end

  context 'role is a Student' do
    let(:role) { create(:student) }

    context 'the grouping exists' do
      context 'vcs submit is true' do
        before { grouping.assignment.update! vcs_submit: true }

        context 'the student is an accepted member of the group' do
          before { create(:accepted_student_membership, role: role, grouping: grouping) }

          context 'the assignment is not hidden for everyone' do
            it 'should succeed' do
              expect(script_success?).to be_truthy
            end

            context 'when the student is hidden' do
              before { role.update!(hidden: true) }

              it 'should fail' do
                expect(script_success?).to be_falsy
              end
            end
          end

          context 'the assignment is hidden for everyone' do
            before { grouping.assignment.update! is_hidden: true }

            it 'should fail' do
              expect(script_success?).to be_falsy
            end
          end

          context 'the assignment is hidden for the section' do
            before do
              create(:assessment_section_properties, assessment: grouping.assignment, section: section, is_hidden: true)
              role.update! section_id: section.id
            end

            it 'should fail' do
              expect(script_success?).to be_falsy
            end
          end

          context 'the assignment is not hidden for the section' do
            before do
              create(:assessment_section_properties, assessment: grouping.assignment, section: section,
                                                     is_hidden: false)
              role.update! section_id: section.id
            end

            it 'should succeed' do
              expect(script_success?).to be_truthy
            end
          end

          context 'the assignment has datetime-based visibility' do
            context 'when visible_on is in the future' do
              before { grouping.assignment.update! visible_on: 1.hour.from_now, visible_until: 2.hours.from_now }

              it 'should fail' do
                expect(script_success?).to be_falsy
              end
            end

            context 'when visible_until is in the past' do
              before { grouping.assignment.update! visible_on: 2.hours.ago, visible_until: 1.hour.ago }

              it 'should fail' do
                expect(script_success?).to be_falsy
              end
            end

            context 'when current time is within visibility window' do
              before { grouping.assignment.update! visible_on: 1.hour.ago, visible_until: 1.hour.from_now }

              it 'should succeed' do
                expect(script_success?).to be_truthy
              end
            end

            context 'when only visible_on is set and in the past' do
              before { grouping.assignment.update! visible_on: 1.hour.ago, visible_until: nil }

              it 'should succeed' do
                expect(script_success?).to be_truthy
              end
            end

            context 'when only visible_until is set and in the future' do
              before { grouping.assignment.update! visible_on: nil, visible_until: 1.hour.from_now }

              it 'should succeed' do
                expect(script_success?).to be_truthy
              end
            end
          end

          context 'the assignment has section-specific datetime visibility' do
            before { role.update! section_id: section.id }

            context 'when section visible_on is in the future' do
              before do
                create(:assessment_section_properties, assessment: grouping.assignment, section: section,
                                                       visible_on: 1.hour.from_now, visible_until: 2.hours.from_now)
              end

              it 'should fail' do
                expect(script_success?).to be_falsy
              end
            end

            context 'when section visible_until is in the past' do
              before do
                create(:assessment_section_properties, assessment: grouping.assignment, section: section,
                                                       visible_on: 2.hours.ago, visible_until: 1.hour.ago)
              end

              it 'should fail' do
                expect(script_success?).to be_falsy
              end
            end

            context 'when current time is within section visibility window' do
              before do
                create(:assessment_section_properties, assessment: grouping.assignment, section: section,
                                                       visible_on: 1.hour.ago, visible_until: 1.hour.from_now)
              end

              it 'should succeed' do
                expect(script_success?).to be_truthy
              end
            end
          end

          context 'the assessment is timed' do
            let(:due_date) { 10.hours.from_now }

            before do
              grouping.assignment.update! is_timed: true,
                                          due_date: due_date,
                                          start_time: 10.hours.ago,
                                          duration: 1.hour
            end

            context 'the grouping has started the assessment' do
              before { grouping.update! start_time: 1.hour.ago }

              it 'should succeed' do
                expect(script_success?).to be_truthy
              end
            end

            context 'the grouping has not started the assessment' do
              context 'the due date has passed' do
                let(:due_date) { 2.hours.ago }

                it 'should succeed' do
                  expect(script_success?).to be_truthy
                end
              end

              context 'the due date has not passed' do
                it 'should fail' do
                  expect(script_success?).to be_falsy
                end
              end
            end
          end
        end

        context 'the student is an inviter member of the group' do
          before { create(:inviter_student_membership, role: role, grouping: grouping) }

          it 'should succeed' do
            expect(script_success?).to be_truthy
          end
        end

        context 'the student is a pending member of the group' do
          before { create(:student_membership, role: role, grouping: grouping) }

          it 'should fail' do
            expect(script_success?).to be_falsy
          end
        end

        context 'the student is a rejected member of the group' do
          before { create(:rejected_student_membership, role: role, grouping: grouping) }

          it 'should fail' do
            expect(script_success?).to be_falsy
          end
        end

        context 'the student is not part of the group' do
          it 'should fail' do
            expect(script_success?).to be_falsy
          end
        end
      end

      context 'vcs submit is false' do
        before { grouping.assignment.update! vcs_submit: false }

        it 'should fail' do
          expect(script_success?).to be_falsy
        end
      end
    end

    context 'when the grouping does not exist' do
      let(:course_name) { role.course.name }
      let(:grouping) { build(:grouping) }

      it 'should fail' do
        expect(script_success?).to be_falsy
      end
    end
  end
end

def exec_query
  ActiveRecord::Base.connection.execute(
    "SELECT check_repo_permissions('#{role.user_name}', '#{course_name}', '#{repo_name}')"
  )
end

def script_success?
  exec_query.first.[]('check_repo_permissions')
end
