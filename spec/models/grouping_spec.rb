require 'spec_helper'

describe Grouping do
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
