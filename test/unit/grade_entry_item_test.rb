require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

# Tests for GradeEntryItems
class GradeEntryItemTest < ActiveSupport::TestCase

  should belong_to :grade_entry_form
  should have_many :grades

  should validate_presence_of :name
  should validate_presence_of :position

  should validate_numericality_of(
            :out_of).with_message(
                I18n.t('grade_entry_forms.invalid_column_out_of'))
  should validate_numericality_of(
             :position)

  should allow_value(0).for(:out_of)
  should allow_value(1).for(:out_of)
  should allow_value(2).for(:out_of)
  should allow_value(100).for(:out_of)
  should allow_value(-1).for(:out_of)
  should allow_value(-100).for(:out_of)

  should allow_value(0).for(:position)
  should allow_value(1).for(:position)
  should allow_value(2).for(:position)
  should allow_value(100).for(:position)
  should_not allow_value(-1).for(:position)
  should_not allow_value(-100).for(:position)

  context 'A good Grade Entry Form ' do
    setup do
      @grade_entry_form = GradeEntryForm.make

    end

    should 'update name if duplicate' do
      item1 = @grade_entry_form.grade_entry_items.make(:name => 'Q1', :out_of => 10, :position => 1)
      item2 = @grade_entry_form.grade_entry_items.make(:name => 'Q1', :out_of => 10, :position => 2)

      assert item1.valid?
      assert item2.valid?
      assert_not_equal item1.name, item2.name
    end


    # Make sure different grade entry forms can have grade entry items
    # with the same name
    should 'allow same column name as a different grade entry form' do
      grade_entry_form_2 = GradeEntryForm.make
      column = @grade_entry_form.grade_entry_items.make(:name => 'Q1', :out_of => 10, :position => 1)

      # Re-use the column name for a different grade entry form
      dup_column = GradeEntryItem.new
      dup_column.name = column.name
      dup_column.out_of = column.out_of
      dup_column.position = column.position
      dup_column.grade_entry_form = grade_entry_form_2

      assert dup_column.valid?
    end
  end


  # Saving should cause invalid inputs to be updated to default
  context 'A Grade Entry Item model with invalid inputs' do

    should 'allow negative out_of values' do
      item = GradeEntryItem.make(:name => 'Q1', :out_of => -10, :position => 1)
      assert item.valid?
      assert_equal 1, item.out_of
    end

    should 'allow empty out_of values' do
      item = GradeEntryItem.make(:name => 'Q1', :out_of => nil, :position => 1)
      assert item.valid?
      assert_equal 1, item.out_of
    end

  end
end
