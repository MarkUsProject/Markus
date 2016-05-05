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

    should validate_presence_of :name
    should validate_presence_of :assignment_id
    should validate_presence_of :max

    should validate_uniqueness_of(
                          :name).scoped_to(
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
      e = assert_raise CSVInvalidLineError do
        FlexibleCriterion.new_from_csv_row([], Assignment.new)
      end
      assert_equal I18n.t('csv.invalid_row.invalid_format'), e.message
    end

    should 'raise an error message on a 1 element row' do
      e = assert_raise CSVInvalidLineError do
        FlexibleCriterion.new_from_csv_row(%w(name), Assignment.new)
      end
      assert_equal I18n.t('csv.invalid_row.invalid_format'), e.message
    end

    should 'raise an error message on a invalid maximum value' do
      e = assert_raise CSVInvalidLineError do
        FlexibleCriterion.new_from_csv_row(%w(name max_value), Assignment.new)
      end
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

    context 'with three flexible criteria' do
      setup do
        FlexibleCriterion.make(:assignment => @assignment,
                              :name => 'criterion1',
                              :description => 'description1, for criterion 1',
                              :max => 10)
        FlexibleCriterion.make(:assignment => @assignment,
                              :name => 'criterion2',
                              :description => 'description2, "with quotes"',
                              :max => 10,
                              :position => 2)
        FlexibleCriterion.make(:assignment => @assignment,
                              :name => 'criterion3',
                              :description => 'description3!',
                              :max => 1.6,
                              :position => 3)
      end

      should 'fail with corresponding error message if the name is already in use' do
        e = assert_raise CSVInvalidLineError do
          FlexibleCriterion.new_from_csv_row(
            ['criterion1', 1.0, 'any description would do'],
            @assignment)
        end
        assert_equal I18n.t('csv.invalid_row.duplicate_entry'), e.message
      end

    end
  end  # An assignment of type flexible criteria
end
