require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'shoulda'

class FlexibleCriterionTest < ActiveSupport::TestCase
  fixtures :all
  should belong_to :assignment

  # Not yet functional
  # should have_many :marks

  should validate_presence_of :flexible_criterion_name
  should validate_presence_of :assignment_id
  should validate_presence_of :max

  should validate_uniqueness_of(:flexible_criterion_name).scoped_to(:assignment_id).with_message('is already taken')
  should validate_numericality_of(:assignment_id).with_message("can only be whole number greater than 0")
  should validate_numericality_of(:max).with_message("must be a number greater than 0.0")

  should allow_value(0.1).for(:max)
  should allow_value(1.0).for(:max)
  should allow_value(100.0).for(:max)
  should_not allow_value(0.0).for(:max)
  should_not allow_value(-1.0).for(:max)
  should_not allow_value(-100.0).for(:max)

  should allow_value(1).for(:assignment_id)
  should allow_value(2).for(:assignment_id)
  should allow_value(100).for(:assignment_id)
  should_not allow_value(0).for(:assignment_id)
  should_not allow_value(-1).for(:assignment_id)
  should_not allow_value(-100).for(:assignment_id)

  # Class methods

  CSV_STRING = "criterion1,10.0,\"description1, for criterion 1\"\ncriterion2,10.0,\"description2, \"\"with quotes\"\"\"\ncriterion3,1.6,description3!\n"
  UPLOAD_CSV_STRING = "criterion4,10.0,\"description4, \"\"with quotes\"\"\"\n"
  INVALID_CSV_STRING = "criterion3\ncriterion1,10.0,\"description1, for criterion 1\"\n"

  context "from an assignment composed of flexible criteria" do
    setup do
      @assignment = assignments(:flexible_assignment)
    end

    should "be able to get a csv string" do
      csv_string = FlexibleCriterion.create_csv(@assignment)
      assert_equal CSV_STRING, csv_string, "the CSV string was not the one expected!"
    end

    should "be able to use a generated string for parsing" do
      csv_string = FlexibleCriterion.create_csv(@assignment)
      tempfile = Tempfile.new('flexible_csv')
      tempfile << csv_string
      tempfile.rewind
      invalid_lines = []
      dst_assignment = assignments(:flexible_assignment_without_criterion)
      nb_updates = FlexibleCriterion.parse_csv(tempfile, dst_assignment, invalid_lines)
      assert_equal 3, nb_updates
      assert_equal 0, invalid_lines.size
    end

  end

  context "from an assignment without criteria" do
    setup do
      @assignment = assignments(:flexible_assignment_without_criterion)
    end

    should "get an empty CSV string" do
      csv_string = FlexibleCriterion.create_csv(@assignment)
      assert_equal "", csv_string, "the CSV string was not the one expected!"
    end
  end

  context "when parsing a CSV file row" do

    should "raise en error message on an empty row" do
      e = assert_raise CSV::IllegalFormatError do
        FlexibleCriterion.new_from_csv_row([], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
    end

    should "raise an error message on a 1 element row" do
      e = assert_raise CSV::IllegalFormatError do
        FlexibleCriterion.new_from_csv_row(['name'], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message
    end

    should "raise an error message on a invalid maximum value" do
      e = assert_raise CSV::IllegalFormatError do
        FlexibleCriterion.new_from_csv_row(['name', 'max_value'], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.max_zero'), e.message
    end

    should "raise the errors hash in case of an unpredicted error" do
      e = assert_raise CSV::IllegalFormatError do
        # That should fail because the assignment doesn't yet exists (in the DB)
        FlexibleCriterion.new_from_csv_row(['name', 10], Assignment.new)
      end
      assert_instance_of ActiveModel::Errors, e.message
    end

    context "and the row is valid" do

      setup do
        # we'll need a valid assignment for those cases.
        @assignment = assignments(:flexible_assignment)
      end

      should "create a new instance from a 2 element row" do
        criterion = FlexibleCriterion.new_from_csv_row(['name', 10.0], @assignment)
        assert_not_nil criterion
        assert_instance_of FlexibleCriterion, criterion
        assert_equal criterion.assignment, @assignment
      end

      should "create a new instance from a 3 elements row" do
        criterion = FlexibleCriterion.new_from_csv_row(['name', 10.0, 'description'], @assignment)
        assert_not_nil criterion
        assert_instance_of FlexibleCriterion, criterion
        assert_equal criterion.assignment, @assignment
      end

      should "fail with corresponding error message if the name is already in use" do
        e = assert_raise CSV::IllegalFormatError do
          FlexibleCriterion.new_from_csv_row(['criterion1', 1.0, 'any description would do'], @assignment)
        end
        assert_equal I18n.t('criteria_csv_error.name_not_unique'), e.message
      end

    end

  end

  should "be able to parse a valid CSV file" do
    tempfile = Tempfile.new('flexible_criteria_csv')
    tempfile << UPLOAD_CSV_STRING
    tempfile.rewind
    assignment = assignments(:flexible_assignment)
    invalid_lines = []

    nb_updates = FlexibleCriterion.parse_csv(tempfile, assignment, invalid_lines)
    assert_equal nb_updates, 1
    assert invalid_lines.empty?
  end

  should "report errors on a invalid CSV file" do
    tempfile = Tempfile.new('flexible_criteria_csv')
    tempfile << INVALID_CSV_STRING
    tempfile.rewind
    assignment = assignments(:flexible_assignment)
    invalid_lines = []

    nb_updates = FlexibleCriterion.parse_csv(tempfile, assignment, invalid_lines)
    assert_equal 0, nb_updates
    assert_equal 2, invalid_lines.length
  end

end
