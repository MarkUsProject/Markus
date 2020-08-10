describe CriterionTaAssociation do
  context 'validations and associations' do
    subject { build_stubbed :criterion_ta_association }
    it { is_expected.to belong_to :ta }
    it { is_expected.to belong_to :criterion }
    it { is_expected.to belong_to :assignment }
    it { is_expected.to allow_values(subject.criterion.assignment.id).for :assessment_id }
  end

  describe '#self.from_csv' do
    let!(:grader) { create :ta, user_name: 'beaker' }
    let(:grader2) { create :ta, user_name: 'drteeth' }
    let(:criterion) { create :flexible_criterion, name: 'criteria1' }
    let!(:cta) { create :criterion_ta_association, criterion: criterion, ta: grader2 }
    it 'should remove existing criterion ta associations' do
      file = file_fixture('criteria_ta_association/simple.csv')
      CriterionTaAssociation.from_csv(cta.assignment, file, true)
      expect { cta.reload }.to raise_error ActiveRecord::RecordNotFound
    end
    it 'should create new criterion ta associations' do
      file = file_fixture('criteria_ta_association/simple.csv')
      CriterionTaAssociation.from_csv(cta.assignment, file, true)
      expect(CriterionTaAssociation.find_by_ta_id_and_criterion_id(grader.id, criterion.id)).not_to be_nil
    end
    it 'should not create a ta that does not exist' do
      file = file_fixture('criteria_ta_association/bad_ta.csv')
      expect { CriterionTaAssociation.from_csv(cta.assignment, file, false) }.not_to(
          change { CriterionTaAssociation.count }
      )
    end
    it 'should not create a criterion that does not exist' do
      file = file_fixture('criteria_ta_association/bad_criterion.csv')
      expect { CriterionTaAssociation.from_csv(cta.assignment, file, false) }.not_to(
          change { CriterionTaAssociation.count }
      )
    end
    it 'should update criterion coverage counts' do
      file = file_fixture('criteria_ta_association/simple.csv')
      grouping = create(:grouping, assignment: criterion.assignment)
      create :ta_membership, grouping: grouping, user: grader
      expect { CriterionTaAssociation.from_csv(cta.assignment, file, false) }.to(
          change { grouping.reload.criteria_coverage_count }
      )
    end
    it 'should update assigned groups counts' do
      file = file_fixture('criteria_ta_association/simple.csv')
      grouping = create(:grouping, assignment: criterion.assignment)
      create :ta_membership, grouping: grouping, user: grader
      expect { CriterionTaAssociation.from_csv(cta.assignment, file, false) }.to(
          change { criterion.reload.assigned_groups_count }
      )
    end
  end
end
