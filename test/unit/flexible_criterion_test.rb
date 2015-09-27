require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class FlexibleCriterionTest < ActiveSupport::TestCase
  # Class methods

  CSV_STRING = "criterion1,10.0,\"description1, for criterion 1\"\ncriterion2,10.0,\"description2, \"\"with quotes\"\"\"\ncriterion3,1.6,description3!\n"
  UPLOAD_CSV_STRING = "criterion4,10.0,\"description4, \"\"with quotes\"\"\"\n"
  INVALID_CSV_STRING = "criterion3\n"

  context 'A good FlexiableCriterion model' do
    setup do
      FlexibleCriterion.make
    end

    should belong_to :assignment

    # Not yet functional
    # should have_many :marks

    should validate_presence_of :flexible_criterion_name
    should validate_presence_of :assignment_id
    should validate_presence_of :max

    should validate_uniqueness_of(
                          :flexible_criterion_name).scoped_to(
                                :assignment_id).with_message(
                                      'Criterion name already used.')

    should validate_numericality_of(
                          :max).with_message(
                                'must be a number greater than 0.0')

    should allow_value(0.1).for(:max)
    should allow_value(1.0).for(:max)
    should allow_value(100.0).for(:max)
    should_not allow_value(0.0).for(:max)
    should_not allow_value(-1.0).for(:max)
    should_not allow_value(-100.0).for(:max)
  end

  context 'With an unexisting criteria' do

    should 'raise en error message on an empty row' do
      e = assert_raise CSV::MalformedCSVError do
        FlexibleCriterion.new_from_csv_row([], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
    end

    should 'raise an error message on a 1 element row' do
      e = assert_raise CSV::MalformedCSVError do
        FlexibleCriterion.new_from_csv_row(%w(name), Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
    end

    should 'raise an error message on a invalid maximum value' do
      e = assert_raise CSV::MalformedCSVError do
        FlexibleCriterion.new_from_csv_row(%w(name max_value), Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.max_zero'), e.message
    end

    should 'raise exceptions in case of an unpredicted error' do
      # Capture exception in variable 'e'
      e = assert_raise CSV::MalformedCSVError do
        # That should fail because the assignment doesn't yet exists (in the DB)
        FlexibleCriterion.new_from_csv_row(['name', 10], Assignment.new)
      end
      assert_instance_of CSV::MalformedCSVError, e
      if RUBY_VERSION > '1.9'
        assert_not_nil(e.message =~ /ActiveModel::Errors/)
      else
        assert_instance_of ActiveModel::Errors, e.message
      end
    end

  end

  context 'An assignment, of type flexible criteria' do
    setup do
      @assignment = Assignment.make(:marking_scheme_type => 'flexible')
    end

    should 'get an empty CSV string' do
      csv_string = FlexibleCriterion.create_csv(@assignment)
      assert_equal '', csv_string, 'the CSV string was not the one expected!'
    end

    should 'be able to parse a valid CSV file' do
      tempfile = Tempfile.new('flexible_criteria_csv')
      tempfile << UPLOAD_CSV_STRING
      tempfile.rewind
      invalid_lines = []

      nb_updates = FlexibleCriterion.parse_csv(tempfile,
                                               @assignment,
                                               invalid_lines)
      assert_equal nb_updates, 1
      assert invalid_lines.empty?
    end


    should 'create a new instance from a 2 element row' do
      criterion = FlexibleCriterion.new_from_csv_row(['name', 10.0],
                                                     @assignment)
      assert_not_nil criterion
      assert_instance_of FlexibleCriterion, criterion
      assert_equal criterion.assignment, @assignment
    end

    should 'create a new instance from a 3 elements row' do
      criterion = FlexibleCriterion.new_from_csv_row(['name',
                                                      10.0,
                                                      'description'],
                                                     @assignment)
      assert_not_nil criterion
      assert_instance_of FlexibleCriterion, criterion
      assert_equal criterion.assignment, @assignment
    end

    should 'report errors on a invalid CSV file' do
      tempfile = Tempfile.new('inv_flexible_criteria_csv')
      tempfile << INVALID_CSV_STRING
      tempfile.rewind
      invalid_lines = []

      nb_updates = FlexibleCriterion.parse_csv(
                        tempfile,
                        @assignment,
                        invalid_lines)
      assert_equal 0, nb_updates
      assert_equal 1, invalid_lines.length
    end

    context 'with three flexible criteria' do
      setup do
        FlexibleCriterion.make(:assignment => @assignment,
                              :flexible_criterion_name => 'criterion1',
                              :description => 'description1, for criterion 1',
                              :max => 10)
        FlexibleCriterion.make(:assignment => @assignment,
                              :flexible_criterion_name => 'criterion2',
                              :description => 'description2, "with quotes"',
                              :max => 10,
                              :position => 2)
        FlexibleCriterion.make(:assignment => @assignment,
                              :flexible_criterion_name => 'criterion3',
                              :description => 'description3!',
                              :max => 1.6,
                              :position => 3)
      end

      should 'be able to get a csv string' do
        csv_string = FlexibleCriterion.create_csv(@assignment)
        assert_equal CSV_STRING, csv_string,
                     'the CSV string was not the one expected!'
      end

      should 'be able to use a generated string for parsing' do
        csv_string = FlexibleCriterion.create_csv(@assignment)
        tempfile = Tempfile.new('flexible_csv')
        tempfile << csv_string
        tempfile.rewind
        invalid_lines = []
        dst_assignment = Assignment.make(:marking_scheme_type => 'flexible')
        nb_updates = FlexibleCriterion.parse_csv(
                                tempfile,
                                dst_assignment, invalid_lines)
        assert_equal 3, nb_updates
        assert_equal 0, invalid_lines.size
      end

      should 'fail with corresponding error message if the name is already in use' do
        e = assert_raise CSV::MalformedCSVError do
          FlexibleCriterion.new_from_csv_row(
            ['criterion1', 1.0, 'any description would do'],
            @assignment)
        end
        assert_equal I18n.t('criteria_csv_error.name_not_unique'), e.message
      end

    end
  end  # An assignment of type flexible criteria
end
