require 'spec_helper'

describe Grouping do
  describe 'assigning and unassigning TAs' do
    let(:assignment) { create(:assignment) }
    let(:groupings) do
      Array.new(2) { create(:grouping, assignment: assignment) }
    end
    let(:tas) { Array.new(2) { create(:ta) } }
    let(:grouping_ids) { groupings.map(&:id) }
    let(:ta_ids) { tas.map(&:id) }

    describe '.randomly_assign_tas' do
      it 'can randomly bulk assign no TAs to no groupings' do
        Grouping.randomly_assign_tas([], [], assignment)
      end

      it 'can randomly bulk assign TAs to no groupings' do
        Grouping.randomly_assign_tas([], ta_ids, assignment)
      end

      it 'can randomly bulk assign no TAs to all groupings' do
        Grouping.randomly_assign_tas(grouping_ids, [], assignment)
      end

      it 'can randomly bulk assign TAs to all groupings' do
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to eq 1
          expect(tas).to include grouping.tas.first
        end
      end

      it 'can randomly bulk assign duplicated TAs to groupings' do
        # The probability of assigning no duplicated TAs after (tas.size + 1)
        # trials is 0.
        (tas.size + 1).times do
          Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
        end

        ta_set = tas.to_set
        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to be_between(1, 2).inclusive
          expect(grouping.tas.to_set).to be_subset(ta_set)
        end
      end

      it 'updates criteria coverage counts after randomly bulk assign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after randomly bulk assign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
      end
    end

    describe '.assign_all_tas' do
      it 'can bulk assign no TAs to no groupings' do
        Grouping.assign_all_tas([], [], assignment)
      end

      it 'can bulk assign all TAs to no groupings' do
        Grouping.assign_all_tas([], ta_ids, assignment)
      end

      it 'can bulk assign no TAs to all groupings' do
        Grouping.assign_all_tas(grouping_ids, [], assignment)
      end

      it 'can bulk assign all TAs to all groupings' do
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to match_array(tas)
        end
      end

      it 'can bulk assign duplicated TAs to groupings' do
        Grouping.assign_all_tas(grouping_ids.first, ta_ids, assignment)
        Grouping.assign_all_tas(grouping_ids, ta_ids.first, assignment)

        # First grouping gets all the TAs.
        grouping = groupings.shift
        grouping.reload
        expect(grouping.tas).to match_array(tas)

        # The rest of the groupings gets only the first TA.
        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to eq [tas.first]
        end
      end

      it 'updates criteria coverage counts after bulk assign all TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after bulk assign all TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        Grouping.unassign_tas([], [], assignment)
      end

      it 'can bulk unassign TAs' do
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
        ta_membership_ids = groupings
          .map { |grouping| grouping.memberships.pluck(:id) }
          .reduce(:+)
        Grouping.unassign_tas(ta_membership_ids, grouping_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to be_empty
        end
      end

      it 'updates criteria coverage counts after bulk unassign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.unassign_tas([], grouping_ids, assignment)
      end

      it 'updates assigned groups counts after bulk unassign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.unassign_tas([], grouping_ids, assignment)
      end
    end
  end

  describe '.update_criteria_coverage_counts' do
    let(:grouping) { create(:grouping) }
    let(:assignment) { grouping.assignment }

    context 'when no grouping IDs are specified' do
      # Verifies the criteria coverage count of +grouping+ is equal to
      # +expected_count+ after updating all the counts.
      def expect_updated_criteria_coverage_count_eq(expected_count)
        Grouping.update_criteria_coverage_counts(assignment)
        grouping.reload
        expect(grouping.criteria_coverage_count).to eq expected_count
      end

      context 'with no assigned TAs' do
        it 'updates criteria coverage count to 0' do
          expect_updated_criteria_coverage_count_eq 0
        end
      end

      context 'with assigned TAs' do
        let!(:tas) { Array.new(2) { create(:ta) } }

        before :each do
          grouping.add_tas(tas)
        end

        context 'with no assigned criteria' do
          it 'updates criteria coverage count to 0' do
            expect_updated_criteria_coverage_count_eq 0
          end
        end

        context 'with assigned criteria' do
          let!(:criteria) do
            # Create more criteria than TAs to verify that irrelevant criteria
            # are not counted. Only `tas.size` number of criteria are assigned
            # TAs.
            Array.new(tas.size + 1) do
              create(:rubric_criterion, assignment: assignment)
            end
          end

          it 'updates criteria coverage count to 0' do
            expect_updated_criteria_coverage_count_eq 0
          end

          context 'when only one is assigned a TA' do
            before(:each) { criteria[0].add_tas(tas[0]) }

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when only one is assigned multiple TAs' do
            before(:each) { criteria[0].add_tas(tas) }

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when `tas.size` are assigned unique TAs' do
            before :each do
              tas.size.times { |i| criteria[i].add_tas(tas[i]) }
            end

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end
          end

          context 'when `tas.size` are assigned non-unique TAs' do
            before(:each) { tas.size.times { |i| criteria[i].add_tas(tas) } }

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end

            context 'when TAs are also assigned to groups of another ' +
                    'assignment' do
              before :each do
                # Creating a new grouping also creates a new assignment.
                grouping = create(:grouping)
                criterion = create(:rubric_criterion,
                                   assignment: grouping.assignment)
                criterion.add_tas(tas)
                grouping.add_tas(tas)
              end

              it 'updates criteria coverage count to `tas.size`' do
                expect_updated_criteria_coverage_count_eq tas.size
              end
            end
          end
        end
      end
    end

    context 'when grouping IDs are specified' do
      let(:another_grouping) { create(:grouping, assignment: assignment) }
      let(:ta) { create(:ta) }
      let(:criterion) { create(:rubric_criterion, assignment: assignment) }
      let(:another_criterion) do
        create(:rubric_criterion, assignment: assignment)
      end

      before :each do
        grouping.add_tas(ta)
        another_grouping.add_tas(ta)
        criterion.add_tas(ta)
        another_criterion.add_tas(ta)
        # Update only `grouping` not `another_grouping`.
        Grouping.update_criteria_coverage_counts(assignment, grouping.id)
      end

      it 'updates the count for the specified grouping' do
        grouping.reload
        expect(grouping.criteria_coverage_count).to eq 2
      end

      it 'does not update the count for the unspecified grouping' do
        another_grouping.reload
        expect(another_grouping.criteria_coverage_count).to eq 0
      end
    end
  end
end
