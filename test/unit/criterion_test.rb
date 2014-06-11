# Tests that apply to all types of criterion. Each specific criterion test
# class can simply include this module to include the tests.
module CriterionTest
  # Runs the tests. This should be called in the test class context.
  @run = lambda do
    context 'a criterion' do
      # Get the specific criterion class to be tested.
      criterion_class = described_type

      setup do
        @criterion = criterion_class.make
        @assignment_id = @criterion.assignment_id
      end

      context 'with no assigned TAs' do
        should 'have 0 assigned groups count after updating the counts' do
          verify_update_assigned_groups_counts(@criterion, 0)
        end
      end

      context 'with assigned TAs' do
        ta_count = 3

        setup do
          @tas = Array.new(ta_count) { Ta.make }
          @criterion.add_tas(@tas)
        end

        context 'that have no assigned groups' do
          should 'have 0 assigned groups count after updating the counts' do
            verify_update_assigned_groups_counts(@criterion, 0)
          end
        end

        context 'that have assigned groups' do
          # Create more groupings than TAs to verify that irrelevant groupings
          # are not counted. Only ta_count number of groupings are assigned
          # TAs.
          grouping_count = ta_count + 2

          setup do
            @groupings = Array.new(grouping_count) do
              Grouping.make(assignment_id: @assignment_id)
            end
          end

          context 'of which only one is assigned a TA' do
            setup { @groupings[0].add_tas(@tas[0]) }

            should 'have 1 assigned groups count after updating the counts' do
              verify_update_assigned_groups_counts(@criterion, 1)
            end
          end

          context 'of which only one is assigned multiple TAs' do
            setup { @groupings[0].add_tas(@tas) }

            should 'have 1 assigned groups count after updating the counts' do
              verify_update_assigned_groups_counts(@criterion, 1)
            end
          end

          context "of which #{ta_count} are assigned unique TAs" do
            setup { ta_count.times { |i| @groupings[i].add_tas(@tas[i]) } }

            should "have #{ta_count} assigned groups count after " +
                   'updating the counts' do
              verify_update_assigned_groups_counts(@criterion, ta_count)
            end
          end

          context "of which #{ta_count} are assigned non-unique TAs" do
            setup { ta_count.times { |i| @groupings[i].add_tas(@tas) } }

            should "have #{ta_count} assigned groups count after " +
                   'updating the counts' do
              verify_update_assigned_groups_counts(@criterion, ta_count)
            end

            context 'who are also assigned to groups of another assignment' do
              setup do
                # Making a new criterion also makes a new assignment.
                criterion = criterion_class.make
                grouping = Grouping.make(assignment: criterion.assignment)
                criterion.add_tas(@tas)
                grouping.add_tas(@tas)
              end

              should "have #{ta_count} assigned groups count after " +
                     'updating the counts' do
                verify_update_assigned_groups_counts(@criterion, ta_count)
              end
            end
          end
        end
      end
    end
  end

  # Called when this module is included in +criterion_test_class+.
  def self.included(criterion_test_class)
    criterion_test_class.class_exec(&@run)
  end

  # Verifies the assigned groups count of +criterion+ is equal to
  # +expected_count+ after updating it.
  def verify_update_assigned_groups_counts(criterion, expected_count)
    criterion.class.update_assigned_groups_counts(criterion.assignment.id)
    criterion.reload
    assert_equal expected_count, criterion.assigned_groups_count
  end
end
