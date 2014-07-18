shared_examples 'a criterion' do
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
