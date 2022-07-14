shared_examples 'a criterion' do
  it { is_expected.to callback(:update_results_with_change).after(:update) }
  it { is_expected.to allow_value(false).for(:bonus) }
  it { is_expected.to allow_value(true).for(:bonus) }
  it { is_expected.to_not allow_value(nil).for(:bonus) }

  describe 'assigning and unassigning TAs' do
    let(:assignment) { FactoryBot.create(:assignment) }
    let(:criteria) do
      Array.new(2) { create(criterion_factory_name, assignment: assignment) }
    end
    let(:tas) { Array.new(2) { create(:ta) } }
    let(:ta_ids) { tas.map(&:id) }
    let(:criterion_ids) { criteria.map(&:id) }
    let(:criterion_one_id) { [criteria[0].id] }

    describe '.randomly_assign_tas' do
      it 'can randomly bulk assign no TAs to no criteria' do
        Criterion.randomly_assign_tas([], [], assignment)
      end

      it 'can randomly bulk assign TAs to no criteria' do
        Criterion.randomly_assign_tas([], ta_ids, assignment)
      end

      it 'can randomly bulk assign no TAs to all criteria' do
        Criterion.randomly_assign_tas(criterion_ids, [], assignment)
      end

      it 'can randomly bulk assign TAs to all criteria' do
        Criterion.randomly_assign_tas(criterion_ids, ta_ids, assignment)

        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas.size).to eq 1
          expect(tas).to include criterion.tas.first
        end
      end

      it 'can randomly bulk assign duplicated TAs to criteria' do
        # The probability of assigning no duplicated TAs after (tas.size + 1)
        # trials is 0.
        (tas.size + 1).times do
          Criterion.randomly_assign_tas(criterion_ids, ta_ids, assignment)
        end
        ta_set = tas.to_set
        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas.size).to be_between(1, 2).inclusive
          expect(criterion.tas.to_set).to be_subset(ta_set)
        end
      end

      it 'updates criteria coverage counts after randomly bulk assign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment)
        Criterion.randomly_assign_tas(criterion_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after randomly bulk assign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts).with(assignment)
        Criterion.randomly_assign_tas(criterion_ids, ta_ids, assignment)
      end
    end

    describe '.assign_all_tas' do
      it 'can bulk assign no TAs to no criteria' do
        Criterion.assign_all_tas([], [], assignment)
      end

      it 'can bulk assign all TAs to no criteria' do
        Criterion.assign_all_tas([], ta_ids, assignment)
      end

      it 'can bulk assign no TAs to all criteria' do
        Criterion.assign_all_tas(criterion_ids, [], assignment)
      end

      it 'can bulk assign all TAs to all criteria' do
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)

        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas).to match_array(tas)
        end
      end

      it 'can bulk assign duplicated TAs to criteria' do
        Criterion.assign_all_tas(criterion_one_id, ta_ids, assignment)
        Criterion.assign_all_tas(criterion_ids, ta_ids.first, assignment)

        # First criterion gets all the TAs.
        criterion = criteria.shift
        criterion.reload
        expect(criterion.tas).to match_array(tas)

        # The rest of the criteria gets only the first TA.
        criteria.each do |other_criterion|
          other_criterion.reload
          expect(other_criterion.tas).to eq [tas.first]
        end
      end

      it 'updates criteria coverage counts after bulk assign all TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment)
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after bulk assign all TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts).with(assignment)
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        Criterion.unassign_tas([], assignment)
      end

      it 'can bulk unassign TAs' do
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
        criteria.each(&:reload)

        criterion_ta_ids = criteria
                           .map { |criterion| criterion.criterion_ta_associations.ids }
                           .reduce(:+)

        Criterion.unassign_tas(criterion_ta_ids, assignment)

        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas).to be_empty
        end
      end

      it 'updates criteria coverage counts after bulk unassign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment)
        Criterion.unassign_tas([], assignment)
      end

      it 'updates assigned groups counts after bulk unassign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts).with(assignment)
        Criterion.unassign_tas([], assignment)
      end
    end
  end

  describe '.update_assigned_groups_counts' do
    let(:assignment) { FactoryBot.create(:assignment) }
    let(:criterion) { create(criterion_factory_name, assignment: assignment) }

    context 'when no criterion IDs are specified' do
      # Verifies the assigned groups count of +criterion+ is equal to
      # +expected_count+ after updating all the counts.
      def expect_updated_assigned_groups_count_to_eq(expected_count)
        Criterion.update_assigned_groups_counts(assignment)
        criterion.reload
        expect(criterion.assigned_groups_count).to eq expected_count
      end

      context 'with no assigned TAs' do
        it 'updates assigned groups count to 0' do
          expect_updated_assigned_groups_count_to_eq 0
        end
      end

      context 'with assigned TAs' do
        let!(:tas) { Array.new(2) { create(:ta) } }

        before :each do
          Criterion.assign_all_tas([criterion.id], tas.map(&:id), criterion.assignment)
        end

        context 'with no assigned groups' do
          it 'updates assigned groups count to 0' do
            expect_updated_assigned_groups_count_to_eq 0
          end
        end

        context 'with assigned groups' do
          let!(:groupings) do
            # Create more groupings than TAs to verify that irrelevant
            # groupings are not counted. Only `tas.size` number of groupings
            # are assigned TAs.
            Array.new(tas.size + 1) do
              create(:grouping, assignment: assignment)
            end
          end

          it 'updates assigned groups count to 0' do
            expect_updated_assigned_groups_count_to_eq 0
          end

          context 'when only one is assigned a TA' do
            before(:each) { create_ta_memberships(groupings[0], tas[0]) }

            it 'updates assigned groups count to 1' do
              expect_updated_assigned_groups_count_to_eq 1
            end
          end

          context 'when only one is assigned multiple TAs' do
            before(:each) { create_ta_memberships(groupings[0], tas) }

            it 'updates assigned groups count to 1' do
              expect_updated_assigned_groups_count_to_eq 1
            end
          end

          context 'when `tas.size` are assigned unique TAs' do
            before :each do
              tas.size.times { |i| create_ta_memberships(groupings[i], tas[i]) }
            end

            it 'updates assigned groups count to `tas.size`' do
              expect_updated_assigned_groups_count_to_eq tas.size
            end
          end

          context 'when `tas.size` are assigned non-unique TAs' do
            before(:each) do
              tas.size.times { |i| create_ta_memberships(groupings[i], tas) }
            end

            it 'updates assigned groups count to `tas.size`' do
              expect_updated_assigned_groups_count_to_eq tas.size
            end

            context 'when TAs are also assigned to groups of another ' \
                    'assignment' do
              before :each do
                # Creating a new criterion also creates a new assignment.
                criterion = create(criterion_factory_name)
                grouping = create(:grouping, assignment: criterion.assignment)
                Criterion.assign_all_tas([[criterion.id, criterion.class.to_s]], tas.map(&:id), criterion.assignment)
                create_ta_memberships(grouping, tas)
              end

              it 'updates assigned groups count to `tas.size`' do
                expect_updated_assigned_groups_count_to_eq tas.size
              end
            end
          end
        end
      end
    end

    context 'with specified criterion IDs' do
      let!(:criterion2) do
        create(criterion_factory_name, assignment: assignment)
      end
      let!(:ta) { create(:ta) }
      let!(:grouping) { create(:grouping, assignment: assignment) }
      let!(:another_grouping) { create(:grouping, assignment: assignment) }

      before :each do
        Criterion.assign_all_tas([criterion.id, criterion2.id],
                                 [ta.id], assignment)
        create_ta_memberships([grouping, another_grouping], ta)
        Criterion.update_assigned_groups_counts(assignment)
      end

      it 'updates the count for both criteria' do
        criterion.reload
        criterion2.reload
        expect(criterion.assigned_groups_count).to eq 2
        expect(criterion2.assigned_groups_count).to eq 2
      end
    end
  end

  describe 'update max_mark' do
    let(:assignment) { create :assignment }
    let(:grouping) { create :grouping_with_inviter, assignment: assignment }
    let(:submission) { create :version_used_submission, grouping: grouping }
    let(:result) { create :incomplete_result, submission: submission }
    let(:mark) do
      mark = result.marks.first
      mark.update!(mark: 1)
      mark.reload
    end
    describe 'when max_mark not updated' do
      let!(:criterion) { create(criterion_factory_name, assignment: assignment, max_mark: 10) }
      it 'should not scale existing marks' do
        prev_mark = mark.mark
        criterion.max_mark = 10
        criterion.save!
        mark.reload
        expect(mark.mark).to eq prev_mark
      end
    end
    describe 'when max_mark is updated' do
      let!(:criterion) { create(criterion_factory_name, assignment: assignment, max_mark: 10) }
      it 'should change existing marks' do
        prev_mark = mark.mark
        criterion.max_mark = 100
        criterion.save!
        mark.reload
        expect(mark.mark).not_to eq prev_mark
      end
      it 'should scale existing marks' do
        prev_mark = mark.mark
        criterion.max_mark *= 10
        criterion.save!
        mark.reload
        if criterion.is_a? CheckboxCriterion
          expect(mark.mark).to eq criterion.max_mark
        else
          expect(mark.mark).to eq prev_mark * 10
        end
      end
    end
  end

  context 'when deleting a criterion' do
    let(:assignment) { create :assignment }
    let(:grouping) { create :grouping_with_inviter, assignment: assignment }
    let(:submission) { create :version_used_submission, grouping: grouping }
    let(:result) { create :incomplete_result, submission: submission }
    let(:mark) do
      mark = result.marks.first
      mark.update!(mark: 1)
      mark.reload
    end
    let(:other_mark) do
      other_mark = result.marks.second
      other_mark.update!(mark: 1)
      other_mark.reload
    end
    let!(:criterion) { create(criterion_factory_name, assignment: assignment, max_mark: 10) }
    let!(:criterion2) { create(criterion_factory_name, assignment: assignment, max_mark: 10) }

    it 'result total marks get updated to reflect the loss of the marks when marking state incomplete' do
      removed_value = mark.mark
      previous_total = mark.mark + other_mark.mark
      criterion2.destroy
      expect(result.reload.total_mark).to eq previous_total - removed_value
    end

    it 'result total marks get updated to reflect the loss of the marks when marking state complete' do
      removed_value = mark.mark
      previous_total = mark.mark + other_mark.mark
      result.update(marking_state: Result::MARKING_STATES[:complete])
      criterion2.destroy
      expect(result.reload.total_mark).to eq previous_total - removed_value
    end

    context 'when there is a percentage extra mark for the result' do
      let!(:extra_mark) { create :extra_mark, result: result, extra_mark: 10 }
      it 'result total marks get updated and percentage bonuses get recalculated' do
        removed_value = mark.mark
        previous_total = mark.mark + other_mark.mark
        new_subtotal = previous_total - removed_value
        new_total = new_subtotal + (criterion.max_mark * 0.1)
        criterion2.destroy
        expect(result.reload.total_mark).to eq new_total
      end
    end
  end

  describe '#grades_array' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    let(:criterion) { create(criterion_factory_name, assignment: assignment) }
    let(:grades) { assignment.groupings.map { rand(criterion.max_mark + 1) } }

    before :each do
      assignment.groupings.each_with_index do |grouping, index|
        mark = grouping.current_result.marks.create(criterion: criterion)
        mark.update(mark: grades[index])
        grouping.current_result.update_total_mark
      end
    end

    it 'returns the grades for their assigned groupings based on assigned criterion marks' do
      expect(criterion.grades_array).to match_array(grades)
    end
  end

  describe '#average' do
    let(:criterion) { create(criterion_factory_name, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(criterion).to receive(:grades_array).and_return([])
      expect(criterion.average).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.average).to eq 2
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      criterion.update(max_mark: 0)
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.average).to eq 0
    end
  end

  describe '#median' do
    let(:criterion) { create(criterion_factory_name, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(criterion).to receive(:grades_array).and_return([])
      expect(criterion.median).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.median).to eq 2
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      criterion.update(max_mark: 0)
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.median).to eq 0
    end
  end

  describe '#standard_deviation' do
    let(:criterion) { create(criterion_factory_name, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(criterion).to receive(:grades_array).and_return([])
      expect(criterion.standard_deviation).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.standard_deviation).to eq 2
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      criterion.update(max_mark: 0)
      allow(criterion).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(criterion.standard_deviation).to eq 0
    end
  end
end
