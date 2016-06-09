require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

# Tests for GradeEntryItems
class GradeEntryItemTest < ActiveSupport::TestCase

  should belong_to :grade_entry_form
  should have_many :grades

  should validate_presence_of :name
  should validate_presence_of :out_of
  should validate_presence_of :position

  should validate_numericality_of(
            :out_of).with_message(
                I18n.t('grade_entry_forms.invalid_column_out_of'))

  should allow_value(0).for(:out_of)
  should allow_value(1).for(:out_of)
  should allow_value(2).for(:out_of)
  should allow_value(100).for(:out_of)
  should_not allow_value(-1).for(:out_of)
  should_not allow_value(-100).for(:out_of)

  should allow_value(0).for(:position)
  should allow_value(1).for(:position)
  should allow_value(2).for(:position)
  should allow_value(100).for(:position)
  should_not allow_value(-1).for(:position)
  should_not allow_value(-100).for(:position)

  context 'A good Grade Entry Item model' do
    setup do
      GradeEntryItem.make(position: 1)
    end

    should validate_uniqueness_of(:name).scoped_to(
            :grade_entry_form_id).with_message(
                I18n.t('grade_entry_forms.invalid_name'))
  end

  # Make sure different grade entry forms can have grade entry items
  # with the same name
  should 'allow same column name for different grade entry forms' do
    grade_entry_form_1 = GradeEntryForm.make
    grade_entry_form_2 = GradeEntryForm.make
    column = grade_entry_form_1.grade_entry_items.make(name: 'Q1', position: 1)

    # Re-use the column name for a different grade entry form
    dup_column = GradeEntryItem.new
    dup_column.name = column.name
    dup_column.out_of = column.out_of
    dup_column.position = column.position
    dup_column.grade_entry_form = grade_entry_form_2

    assert dup_column.valid?
  end

end
