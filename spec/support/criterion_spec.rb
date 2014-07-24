shared_examples 'a criterion' do
  describe 'assigning and unassigning TAs' do
    let(:assignment) { create(assignment_factory_name) }
    let(:criteria) do
      Array.new(2) { create(criterion_factory_name, assignment: assignment) }
    end
    let(:tas) { Array.new(2) { create(:ta) } }
    let(:criterion_ids) { criteria.map(&:id) }
    let(:ta_ids) { tas.map(&:id) }

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
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment, match_array(criterion_ids))
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
        Criterion.assign_all_tas(criterion_ids.first, ta_ids, assignment)
        Criterion.assign_all_tas(criterion_ids, ta_ids.first, assignment)

        # First criterion gets all the TAs.
        criterion = criteria.shift
        criterion.reload
        expect(criterion.tas).to match_array(tas)

        # The rest of the criteria gets only the first TA.
        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas).to eq [tas.first]
        end
      end

      it 'updates criteria coverage counts after bulk assign all TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment)
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after bulk assign all TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment, match_array(criterion_ids))
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        Criterion.unassign_tas([], [], assignment)
      end

      it 'can bulk unassign TAs' do
        Criterion.assign_all_tas(criterion_ids, ta_ids, assignment)
        criterion_ta_ids = criteria
          .map { |criterion| criterion.criterion_ta_associations.pluck(:id) }
          .reduce(:+)
        Criterion.unassign_tas(criterion_ta_ids, criterion_ids, assignment)

        criteria.each do |criterion|
          criterion.reload
          expect(criterion.tas).to be_empty
        end
      end

      it 'updates criteria coverage counts after bulk unassign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment)
        Criterion.unassign_tas([], criterion_ids, assignment)
      end

      it 'updates assigned groups counts after bulk unassign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment, match_array(criterion_ids))
        Criterion.unassign_tas([], criterion_ids, assignment)
      end
    end
  end

  describe '.update_assigned_groups_counts' do
    let(:criterion) { create(criterion_factory_name) }
    let(:assignment) { criterion.assignment }

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
          criterion.add_tas(tas)
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
            before(:each) { groupings[0].add_tas(tas[0]) }

            it 'updates assigned groups count to 1' do
              expect_updated_assigned_groups_count_to_eq 1
            end
          end

          context 'when only one is assigned multiple TAs' do
            before(:each) { groupings[0].add_tas(tas) }

            it 'updates assigned groups count to 1' do
              expect_updated_assigned_groups_count_to_eq 1
            end
          end

          context 'when `tas.size` are assigned unique TAs' do
            before :each do
              tas.size.times { |i| groupings[i].add_tas(tas[i]) }
            end

            it 'updates assigned groups count to `tas.size`' do
              expect_updated_assigned_groups_count_to_eq tas.size
            end
          end

          context 'when `tas.size` are assigned non-unique TAs' do
            before(:each) { tas.size.times { |i| groupings[i].add_tas(tas) } }

            it 'updates assigned groups count to `tas.size`' do
              expect_updated_assigned_groups_count_to_eq tas.size
            end

            context 'when TAs are also assigned to groups of another ' +
                    'assignment' do
              before :each do
                # Creating a new criterion also creates a new assignment.
                criterion = create(criterion_factory_name)
                grouping = create(:grouping, assignment: criterion.assignment)
                criterion.add_tas(tas)
                grouping.add_tas(tas)
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
      let(:another_criterion) do
        create(criterion_factory_name, assignment: assignment)
      end
      let(:ta) { create(:ta) }
      let(:grouping) { create(:grouping, assignment: assignment) }
      let(:another_grouping) { create(:grouping, assignment: assignment) }

      before :each do
        criterion.add_tas(ta)
        another_criterion.add_tas(ta)
        grouping.add_tas(ta)
        another_grouping.add_tas(ta)
        # Update only `criterion` not `another_criterion`.
        Criterion.update_assigned_groups_counts(assignment, criterion.id)
      end

      it 'updates the count for the specified criterion' do
        criterion.reload
        expect(criterion.assigned_groups_count).to eq 2
      end

      it 'does not update the count for the unspecified criterion' do
        another_criterion.reload
        expect(another_criterion.assigned_groups_count).to eq 0
      end
    end
  end
end
