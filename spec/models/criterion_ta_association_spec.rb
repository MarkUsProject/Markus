describe CriterionTaAssociation do
  context 'validations and associations' do
    subject { create(:criterion_ta_association) }

    it { is_expected.to belong_to :ta }
    it { is_expected.to belong_to :criterion }
    it { is_expected.to belong_to :assignment }
    it { is_expected.to allow_values(subject.criterion.assignment.id).for :assessment_id }
    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'

    it 'allows instructors to be graders' do
      criterion = create(:rubric_criterion)
      instructor = create(:instructor, course: criterion.assignment.course)

      expect(build(:criterion_ta_association, criterion: criterion, ta: instructor)).to be_valid
    end

    it 'does not allow students to be graders' do
      criterion = create(:rubric_criterion)
      student = create(:student, course: criterion.assignment.course)
      association = build(:criterion_ta_association, criterion: criterion, ta: student)

      expect(association).not_to be_valid
      expect(association.errors.of_kind?(:ta, :invalid)).to be true
    end

    it 'does not allow admin roles to be graders' do
      criterion = create(:rubric_criterion)
      admin_role = create(:admin_role, course: criterion.assignment.course)
      association = build(:criterion_ta_association, criterion: criterion, ta: admin_role)

      expect(association).not_to be_valid
      expect(association.errors.of_kind?(:ta, :invalid)).to be true
    end
  end

  describe '#self.from_csv' do
    let!(:grader) do
      create(:ta, user_attributes: { user_name: 'beaker', last_name: 'beaker', first_name: 'beaker', type: 'EndUser' })
    end
    let(:grader2) do
      create(:ta,
             user_attributes: { user_name: 'drteeth', last_name: 'drteeth', first_name: 'drteeth', type: 'EndUser' })
    end
    let(:criterion) { create(:flexible_criterion, name: 'criteria1') }
    let!(:cta) { create(:criterion_ta_association, criterion: criterion, ta: grader2) }

    it 'should remove existing criterion ta associations' do
      file = file_fixture('criteria_ta_association/simple.csv')
      CriterionTaAssociation.from_csv(cta.assignment, file.read, true)
      expect { cta.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should create new criterion ta associations' do
      file = file_fixture('criteria_ta_association/simple.csv')
      CriterionTaAssociation.from_csv(cta.assignment, file.read, true)
      expect(CriterionTaAssociation.find_by(ta_id: grader.id, criterion_id: criterion.id)).not_to be_nil
    end

    it 'creates criterion associations for instructors' do
      instructor = create(:instructor, course: criterion.assignment.course,
                                       user: create(:end_user, user_name: 'professor'))
      csv_data = "#{criterion.name},#{instructor.user_name}"

      expect { CriterionTaAssociation.from_csv(criterion.assignment, csv_data, false) }
        .to change { CriterionTaAssociation.count }.by(1)
      expect(criterion.reload.tas).to include(instructor)
    end

    it 'should not create a ta that does not exist' do
      file = file_fixture('criteria_ta_association/bad_ta.csv')
      expect { CriterionTaAssociation.from_csv(cta.assignment, file.read, false) }.not_to(
        change { CriterionTaAssociation.count }
      )
    end

    it 'should not create a criterion that does not exist' do
      file = file_fixture('criteria_ta_association/bad_criterion.csv')
      expect { CriterionTaAssociation.from_csv(cta.assignment, file.read, false) }.not_to(
        change { CriterionTaAssociation.count }
      )
    end

    it 'should update criterion coverage counts' do
      file = file_fixture('criteria_ta_association/simple.csv')
      grouping = create(:grouping, assignment: criterion.assignment)
      create(:ta_membership, grouping: grouping, role: grader)
      expect { CriterionTaAssociation.from_csv(cta.assignment, file.read, false) }.to(
        change { grouping.reload.criteria_coverage_count }
      )
    end

    it 'should update assigned groups counts' do
      file = file_fixture('criteria_ta_association/simple.csv')
      grouping = create(:grouping, assignment: criterion.assignment)
      create(:ta_membership, grouping: grouping, role: grader)
      expect { CriterionTaAssociation.from_csv(cta.assignment, file.read, false) }.to(
        change { criterion.reload.assigned_groups_count }
      )
    end
  end
end
