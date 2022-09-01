describe Role do
  let(:course) { create(:course) }
  let(:student) { create(:student, course: course) }

  it { is_expected.to allow_value('Student').for(:type) }
  it { is_expected.to allow_value('Instructor').for(:type) }
  it { is_expected.to allow_value('Ta').for(:type) }
  it { is_expected.to allow_value('AdminRole').for(:type) }
  it { is_expected.not_to allow_value('OtherTypeOfUser').for(:type) }
  it { is_expected.to have_many :memberships }
  it { is_expected.to have_many(:groupings).through(:memberships) }
  it { is_expected.to have_many(:notes).dependent(:destroy) }
  it { expect(student).to validate_uniqueness_of(:user_id).scoped_to(:course_id) }

  context 'A good Role model' do
    it 'should be able to create a student' do
      create(:student, course_id: course.id)
    end
    it 'should be able to create an instructor' do
      create(:instructor, course_id: course.id)
    end
    it 'should be able to create a grader' do
      create(:ta, course_id: course.id)
    end
  end

  context 'The repository permissions file' do
    context 'should be upated' do
      it 'when creating an instructor' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        create(:instructor)
      end
      it 'when destroying an instructor' do
        instructor = create(:instructor)
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        instructor.destroy
      end

      context 'when updating the hidden status' do
        it 'for a single instructor' do
          instructor = create :instructor
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          instructor.update(hidden: true)
        end

        it 'for a single ta' do
          grader = create :ta
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          grader.update(hidden: true)
        end

        it 'for a single student' do
          student = create :student
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          student.update(hidden: true)
        end

        it 'after bulk hiding students' do
          student1 = create :student
          student2 = create :student
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Student.hide_students([student1.id, student2.id])
        end

        it 'after bulk unhiding students' do
          student1 = create :student
          student2 = create :student
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          Student.unhide_students([student1.id, student2.id])
        end
      end
    end
    context 'should not be updated' do
      it 'when creating a ta' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:ta)
      end
      it 'when destroying a ta without memberships' do
        ta = create(:ta)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        ta.destroy
      end
      it 'when creating a student' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:student)
      end
      it 'when destroying a student without memberships' do
        student = create(:student)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        student.destroy
      end
    end
  end

  describe '#visible_assessments' do
    let(:new_section) { create(:section, course: course) }
    let(:assignment_visible) do
      create(:assignment,
             due_date: 2.days.from_now,
             assignment_properties_attributes: { section_due_dates_type: true },
             course: course)
    end
    let(:assessment_section_properties_visible) do
      create(:assessment_section_properties, assessment: assignment_visible,
                                             section: new_section,
                                             due_date: 2.days.from_now,
                                             is_hidden: false)
    end
    let(:assignment_hidden) do
      create(:assignment,
             due_date: 2.days.from_now,
             assignment_properties_attributes: { section_due_dates_type: true },
             course: course)
    end
    let(:assessment_section_properties_hidden) do
      create(:assessment_section_properties, assessment: assignment_hidden,
                                             section: new_section,
                                             due_date: 2.days.from_now,
                                             is_hidden: true)
    end
    let(:assignment_hidden_section_visible) do
      create(:assignment,
             due_date: 2.days.from_now,
             assignment_properties_attributes: { section_due_dates_type: true },
             is_hidden: true,
             course: course)
    end

    let(:assessment_section_properties_visible_assignment_hidden) do
      create(:assessment_section_properties, assessment: assignment_hidden_section_visible,
                                             section: new_section,
                                             due_date: 2.days.from_now,
                                             is_hidden: false)
    end
    context 'when there are no assessments' do
      let(:new_user) { create :student, course: course }
      it 'should return an empty list' do
        expect(new_user.visible_assessments).to be_empty
      end
    end
    context 'when there are assessments' do
      before(:each) do
        assessment_section_properties_hidden
        assessment_section_properties_visible
      end
      context 'when section_due_dates_type disabled' do
        let(:new_user2) { create :student, course: course }
        it 'does return all unhiddden assignments' do
          expect(new_user2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when user has one visible assignment' do
        let(:new_user) { create :student, section_id: new_section.id, course: course }

        it 'does return a list containing that assignment' do
          expect(new_user.visible_assessments).to contain_exactly(assignment_visible)
        end
      end
      context 'when user has no section' do
        let(:new_user2) { create :student, course: course }
        it 'does return all section-hidden assignments' do
          expect(new_user2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when a user is from a different section' do
        let(:section2) { create :section }
        let(:new_user2) { create :student, section_id: section2, course: course }
        it 'does return all visible assignments' do
          expect(new_user2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when an assignment is hidden' do
        let(:hidden_assignment) do
          create :assignment,
                 due_date: 2.days.from_now,
                 is_hidden: true,
                 assignment_properties_attributes: { section_due_dates_type: true },
                 course: course
        end
        let(:new_user) { create :student, course: course }
        it 'does not return the hidden assignment' do
          expect(new_user.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when a visible assignment is given' do
        let(:new_user) { create :student, section_id: new_section.id, course: course }
        it 'does return an array with the assignment' do
          expect(new_user.visible_assessments(assessment_id: assignment_visible.id))
            .to contain_exactly(assignment_visible)
        end
      end
      context 'when a hidden assignment is given' do
        let(:new_user) { create :student, section_id: new_section.id, course: course }
        it 'does return an empty array' do
          expect(new_user.visible_assessments(assessment_id: assignment_hidden.id)).to be_empty
        end
      end
    end
    context 'when assignment is hidden but section is not' do
      let(:new_user) { create :student, section_id: new_section.id, course: course }
      it 'does return the assignment' do
        assessment_section_properties_visible_assignment_hidden
        expect(new_user.visible_assessments(assessment_id: assignment_hidden_section_visible.id))
          .to contain_exactly(assignment_hidden_section_visible)
      end
    end
    context 'when assignment and section are hidden' do
      let(:new_user) { create :student, section_id: new_section.id, course: course }
      let(:new_hidden_assignment) do
        create :assignment,
               is_hidden: true,
               assignment_properties_attributes: { section_due_dates_type: true },
               course: course
      end
      let(:new_visible_assessment_section_properties) do
        create :assessment_section_properties,
               assessment: new_hidden_assignment,
               section: new_section,
               is_hidden: true
      end
      it 'should return an empty array' do
        assessment_section_properties_hidden
        assessment_section_properties_visible
        new_visible_assessment_section_properties
        expect(new_user.visible_assessments(assessment_id: new_hidden_assignment.id))
          .to be_empty
      end
    end
    context 'when getting a list of assignments with some overridden is_hiddens' do
      let(:new_user) { create :student, section_id: new_section.id, course: course }
      let(:new_hidden_assignment) do
        create :assignment,
               is_hidden: true,
               assignment_properties_attributes: { section_due_dates_type: true },
               course: course
      end
      let(:new_visible_assessment_section_properties) do
        create :assessment_section_properties,
               assessment: new_hidden_assignment,
               section: new_section,
               is_hidden: false
      end
      it 'does return the list of visible assignments for the section' do
        assessment_section_properties_hidden
        assessment_section_properties_visible
        new_visible_assessment_section_properties
        expect(new_user.visible_assessments).to contain_exactly(new_hidden_assignment, assignment_visible)
      end

      context 'when getting a list of assignments with some nil is_hiddens' do
        let(:new_user) { create :student, section_id: new_section.id, course: course }
        let(:new_hidden_assignment) do
          create :assignment,
                 is_hidden: true,
                 assignment_properties_attributes: { section_due_dates_type: true },
                 course: course
        end
        let(:new_visible_assessment_section_properties) do
          create :assessment_section_properties,
                 assessment: new_hidden_assignment,
                 section: new_section
        end
        it 'does return the list of visible assignments for the section' do
          assessment_section_properties_hidden
          assessment_section_properties_visible
          new_visible_assessment_section_properties
          expect(new_user.visible_assessments).to contain_exactly(new_hidden_assignment, assignment_visible)
        end
      end
      context 'when there is a peer review assignment' do
        let(:new_user) { create :student, section: new_section, course: course }
        let(:peer_review) do
          create :assignment,
                 is_hidden: true,
                 parent_assignment: assignment_hidden,
                 assignment_properties_attributes: { section_due_dates_type: true,
                                                     has_peer_review: true },
                 course: course
        end
        let(:peer_review_section) do
          create :assessment_section_properties, section: new_section,
                                                 assessment: peer_review, is_hidden: true
        end
        it 'does appear hidden' do
          assessment_section_properties_hidden
          peer_review_section
          expect(new_user.visible_assessments).to be_empty
        end
        context 'when there is a visible peer review' do
          before do
            peer_review_section.update(is_hidden: false)
          end
          it 'does return the peer review' do
            peer_review_section
            expect(new_user.visible_assessments).to contain_exactly(assignment_hidden, peer_review)
          end
        end
      end
      context 'when getting multiple unhidden assignments' do
        let(:new_user) { create :student, section_id: new_section.id, course: course }
      end
    end

    context 'when using grade entry forms' do
      let(:grade_entry_form_visible) { create :grade_entry_form, course: course }
      let(:grade_entry_section_visible) do
        create :assessment_section_properties, assessment: grade_entry_form_visible,
                                               section: new_section, is_hidden: false
      end

      let(:grade_entry_form_hidden) { create :grade_entry_form, course: course }
      let(:grade_entry_section_hidden) do
        create :assessment_section_properties, assessment: grade_entry_form_hidden,
                                               section: new_section, is_hidden: true
      end

      context 'when there are assessments' do
        before(:each) do
          grade_entry_section_visible
          grade_entry_section_hidden
        end
        context 'when section_due_date_type disabled' do
          let(:new_user2) { create :student, course: course }
          it 'does return all unhiddden assignments' do
            expect(new_user2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when user has one visible assignment' do
          let(:new_user) { create :student, section_id: new_section.id, course: course }

          it 'does return a list containing that assignment' do
            expect(new_user.visible_assessments).to contain_exactly(grade_entry_form_visible)
          end
        end
        context 'when user has no section' do
          let(:new_user2) { create :student, course: course }
          it 'does return all section-hidden assignments' do
            expect(new_user2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when a user is from a different section' do
          let(:section2) { create :section, course: course }
          let(:new_user2) { create :student, section_id: section2, course: course }
          it 'does return all visible assignments' do
            expect(new_user2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when an assignment is hidden' do
          let(:hidden_grade_entry_form) do
            create :grade_entry_form,
                   due_date: 2.days.from_now,
                   is_hidden: true,
                   course: course
          end
          let(:new_user) { create :student, course: course }
          it 'does not return the hidden assignment' do
            expect(new_user.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when a visible assignment is given' do
          let(:new_user) { create :student, section_id: new_section.id, course: course }
          it 'does return an array with the assignment' do
            expect(new_user.visible_assessments(assessment_id: grade_entry_form_visible.id))
              .to contain_exactly(grade_entry_form_visible)
          end
        end
        context 'when a hidden assignment is given' do
          let(:new_user) { create :student, section_id: new_section.id, course: course }
          it 'does return an empty array' do
            expect(new_user.visible_assessments(assessment_id: grade_entry_form_hidden.id)).to be_empty
          end
        end
      end
    end
  end
end
