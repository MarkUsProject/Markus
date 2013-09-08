require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'mocha/setup'
require 'machinist'

class RubricCriterionTest < ActiveSupport::TestCase

  should validate_presence_of :assignment_id
  should validate_numericality_of :assignment_id
  should validate_numericality_of :weight
  should validate_presence_of :weight

  should validate_presence_of :rubric_criterion_name

# FIXME there should be an easy "default" shoulda way to test the uniqueness
# on the name on a specific scope

#  context "a valid Rubric Criterion model" do
#    setup do
#      RubricCriterion.make
#    end
#
#    should validate_uniqueness_of(
#                :rubric_criterion_name).scope(:assignment_d)
#  end

  #Test that Criteria assigned to non-existant Assignment
  #is NOT OK
  def test_assignment_id_dne
    assignment_id_dne = RubricCriterion.make()
    assignment_id_dne.assignment = Assignment.new
    assert !assignment_id_dne.save
  end

  should 'round weights that have more than 3 significant digits' do
    RubricCriterion.make
    assert RubricCriterion.count > 0
    criterion = RubricCriterion.first
    criterion.weight = 0.5555555555
    criterion.save
    assert_equal 0.556, criterion.weight
  end

  should 'find a mark for a specific rubric and result' do
    assignment = Assignment.make
    grouping = Grouping.make(:assignment => assignment)
    submission = Submission.make(:grouping => grouping)
    result = Result.make(:submission => submission)

    rubric = RubricCriterion.make(:assignment => assignment)

    mark = Mark.make(:result => result,
                    :markable => rubric)
    assert_not_nil rubric.mark_for(result.id)
  end

  should 'Set default levels' do
    r = RubricCriterion.new
    assert r.set_default_levels
    r.save
    assert_equal(I18n.t('rubric_criteria.defaults.level_0'), r.level_0_name)
    assert_equal(I18n.t('rubric_criteria.defaults.level_1'), r.level_1_name)
    assert_equal(I18n.t('rubric_criteria.defaults.level_2'), r.level_2_name)
    assert_equal(I18n.t('rubric_criteria.defaults.level_3'), r.level_3_name)
    assert_equal(I18n.t('rubric_criteria.defaults.level_4'), r.level_4_name)
  end

  should 'be able to set all the level names at once' do
    r = RubricCriterion.new
    levels = []
    0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
      levels << 'l' + i.to_s()
    end
    r.expects(:save).once
    r.set_level_names(levels)
    0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
      assert_equal r['level_' + i.to_s() + '_name'], 'l' + i.to_s()
    end
  end

  # TA Assignment tests
  context ' a Rubric Criterion assigning a TA' do

    setup do
      @criterion = RubricCriterion.make
      @ta = Ta.make
    end

    teardown do
      destroy_repos
    end

    should 'assign a TA by id' do
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      assert_equal 1, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
    end

    should 'not assign the same TA multiple times' do
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      @ta.reload
      @criterion.add_tas(@ta)
      assert_equal 1, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
    end

    should 'unassign a TA by id' do
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      assert_equal 1, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @ta.reload
      @criterion.remove_tas(@ta)
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
    end

    should 'assign multiple TAs' do
      @ta1 = Ta.make
      @ta2 = Ta.make
      @ta3 = Ta.make
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.add_tas([@ta1, @ta2, @ta3])
      assert_equal 3, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
    end

    should 'remove multiple TAs' do
      @ta1 = Ta.make
      @ta2 = Ta.make
      @ta3 = Ta.make
      assert_equal 0, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.add_tas([@ta1, @ta2, @ta3])
      assert_equal 3, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @ta1.reload; @ta2.reload; @ta3.reload
      @criterion.remove_tas([@ta1, @ta3])
      assert_equal 1, @criterion.criterion_ta_associations.count, 'Got unexpected TA membership count'
      @criterion.reload
      assert_equal @ta2.id, @criterion.tas[0].id, 'Did not remove the right TA'
    end

    should 'get the names of TAs assigned to it' do
      @ta1 = Ta.make(:user_name => 'g9browni')
      @ta2 = Ta.make(:user_name => 'c7benjam')
      @criterion.add_tas(@ta1)
      @criterion.add_tas(@ta2)
      assert_contains @criterion.get_ta_names, 'g9browni'
      assert_contains @criterion.get_ta_names, 'c7benjam'
    end
  end

  context 'from an assignment composed of rubric criteria' do
    setup do
      @csv_string = "Algorithm Design,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Documentation,2.7,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
      @assignment = Assignment.make(:marking_scheme_type => 'rubric')
      RubricCriterion.make(:assignment => @assignment,
                           :rubric_criterion_name => 'Algorithm Design',
                           :weight => 2.0)
      RubricCriterion.make(:assignment => @assignment,
                           :rubric_criterion_name => 'Documentation',
                           :weight => 2.7)

    end

    should 'be able to get a CSV string' do
      s = RubricCriterion.create_csv(@assignment)
      assert_equal @csv_string, s
    end

    should 'be able to use a generated string for parsing' do
      csv_string = RubricCriterion.create_csv(@assignment)
      tempfile = Tempfile.new('rubric_csv')
      tempfile << csv_string
      tempfile.rewind
      invalid_lines = []
      dst_assignment =  Assignment.make(:marking_scheme_type => 'rubric')
      nb_updates = RubricCriterion.parse_csv(tempfile, dst_assignment, invalid_lines, nil)
      assert_equal 2, nb_updates
      assert_equal 0, invalid_lines.size
      dst_assignment.reload
      assert_equal 2, dst_assignment.rubric_criteria.size
    end
  end

  context 'from an assignment composed of rubric criteria with commas and quotes in the descriptions' do
    setup do
      @csv_string = "Part 1 Programming,2.0,Horrible,Poor,Satisfactory,Good,Excellent,\"Makes the TA \"\"Shivers\"\"\",\"Leaves the TA \"\"calm\"\"\",\"Makes the TA \"\"grin\"\"\",\"Makes the TA \"\"smile\"\"\",\"Makes, the TA scream: \"\"at last, it was about time\"\"\"\n"
      @assignment = Assignment.make
      RubricCriterion.make(:assignment => @assignment,
                           :rubric_criterion_name => 'Part 1 Programming',
                           :weight => 2.0,
                           :level_0_description => 'Makes the TA "Shivers"',
                           :level_1_description => 'Leaves the TA "calm"',
                           :level_2_description => 'Makes the TA "grin"',
                           :level_3_description => 'Makes the TA "smile"',
                           :level_4_description => 'Makes, the TA scream: "at last, it was about time"'
                           )
    end

    should 'be able to get a CSV string' do
      s = RubricCriterion.create_csv(@assignment)
      assert_equal @csv_string, s
    end

    should 'be able to use a generated string for parsing' do
      csv_string = RubricCriterion.create_csv(@assignment)
      tempfile = Tempfile.new('rubric_csv')
      tempfile << csv_string
      tempfile.rewind
      invalid_lines = []
      dst_assignment = Assignment.make
      nb_updates = RubricCriterion.parse_csv(tempfile, dst_assignment, invalid_lines, nil)
      assert_equal 1, nb_updates
      assert_equal 0, invalid_lines.size
      dst_assignment.reload
      assert_equal 1, dst_assignment.rubric_criteria.size
    end
  end

  context 'from an assignment without criteria' do
    setup do
      @assignment = Assignment.make
    end

    should 'be able to get an empty CSV string' do
      csv_string = RubricCriterion.create_csv(@assignment)
      assert_equal '', csv_string
    end

    context 'when parsing a CSV file' do

      should 'raise an error message on an empty row' do
        e = assert_raise RuntimeError do
          RubricCriterion.create_or_update_from_csv_row([], Assignment.new)
        end
        assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
      end

      should 'raise an error message on a 1 element row' do
        e = assert_raise RuntimeError do
          RubricCriterion.create_or_update_from_csv_row(%w(name), Assignment.new)
        end
        assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
      end

      should 'raise an error message on a 2 element row' do
        e = assert_raise RuntimeError do
          RubricCriterion.create_or_update_from_csv_row(%w(name 1.0), Assignment.new)
        end
        assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
      end

      should 'raise an error message on a row with any number of elements that does not include a name for every criterion' do
        row = %w(name 1.0)
        (0..RubricCriterion::RUBRIC_LEVELS - 2).each do |i|
          row << 'name' + i.to_s
            e = assert_raise RuntimeError do
              RubricCriterion.create_or_update_from_csv_row(row, Assignment.new)
            end
            assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
        end
      end

      should 'raise an error message on a row with an invalid weight' do
        row = %w(name weight l0 l1 l2 l3 l4)
        e = assert_raise ActiveRecord::RecordNotSaved do
          RubricCriterion.create_or_update_from_csv_row(row, Assignment.new)
        end
        assert_instance_of ActiveRecord::RecordNotSaved, e
      end

      should 'raise the errors hash in case of an unpredicted error' do
        e = assert_raise ActiveRecord::RecordNotSaved do
          # That should fail because the assignment doesn't yet exists (in the DB)
          RubricCriterion.create_or_update_from_csv_row(%w(name 10 l0 l1 l2 l3 l4), Assignment.new)
        end
        assert_instance_of ActiveRecord::RecordNotSaved, e
      end

      context 'and the row is valid' do

        setup do
          # we'll need a valid assignment for those cases.
          @assignment = Assignment.make
          # and a valid csv row...
          row = ['criterion 5', '1.0']
          (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
            row << 'name' + i.to_s
          end
          # ...containing commas and quotes in the descriptions
          (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
            row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
          end
          @csv_base_row = row
        end

        should 'be able to create a new instance without level descriptions' do
          criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
          assert_not_nil criterion
          assert_instance_of RubricCriterion, criterion
          assert_equal criterion.assignment, @assignment
          (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
            assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
          end
        end

        context 'and there is an existing rubric criterion with the same name' do
          setup do
            criterion = RubricCriterion.new
            criterion.set_default_levels
            # 'criterion 5' is the name used in the criterion held
            # in @csv_base_row - but they use different level names/descriptions.
            # I'll use the defaults here, and see if I can overwrite with
            # @csv_base_row.
            criterion.rubric_criterion_name = 'criterion 5'
            criterion.assignment = @assignment
            criterion.position = @assignment.next_criterion_position
            criterion.weight = 5.0
            assert criterion.save
          end
          should 'allow a criterion with the same name to overwrite' do
            assert_nothing_raised do
              criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
              (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
                assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
              end
              assert_equal 1.0, criterion.weight
            end

          end
        end

        should 'be able to create a new instance with level descriptions' do
          (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
            @csv_base_row << 'description' + i.to_s
          end
          criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
          assert_not_nil criterion
          assert_instance_of RubricCriterion, criterion
          assert_equal criterion.assignment, @assignment
          (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
            assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
            assert_equal 'description' + i.to_s + ' with comma (,) and ""quotes""',
                         criterion['level_' + i.to_s + '_description']
          end
        end

      end

    end

    should 'be able to parse a valid CSV file' do
      tempfile = Tempfile.new('rubric_criteria_csv')
      tempfile << "criterion 6,1.0,l0,l1,l2,l3,l4,d0,d1,d2,d3,d4\n"
      tempfile.rewind
      assignment = Assignment.make
      invalid_lines = []

      nb_updates = RubricCriterion.parse_csv(tempfile, assignment, invalid_lines, nil)
      assert_equal nb_updates, 1
      assert invalid_lines.empty?
    end

    should 'report errors on a invalid CSV file' do
      tempfile = Tempfile.new('flexible_criteria_csv')
      tempfile << "criterion 6\n,criterion 7\n"
      tempfile.rewind
      assignment = Assignment.make
      invalid_lines = []

      nb_updates = RubricCriterion.parse_csv(tempfile, assignment, invalid_lines, nil)
      assert_equal 0, nb_updates
      assert_equal 2, invalid_lines.length
    end
  end

  ####################   HELPERS    #################################

  # Helper method for test_validate_presence_of to create a criterion without
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_rubric_criteria = {
      :rubric_criterion_name => 'somecriteria',
      :assignment_id => Assignment.make,
      :weight => 0.25,
      :level_0_name => 'Horrible',
      :level_1_name => 'Poor',
      :level_2_name => 'Satisfactory',
      :level_3_name => 'Good',
      :level_4_name => 'Excellent'
    }

    new_rubric_criteria.delete(attr) if attr
    RubricCriterion.new(new_rubric_criteria)
  end



end
