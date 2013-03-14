require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require 'shoulda'

# Tests for Grades
class GradeTest < ActiveSupport::TestCase

  # Basic validation tests
  should belong_to :grade_entry_item
  should belong_to :grade_entry_student

  should validate_numericality_of(:grade).with_message(I18n.t('grade_entry_forms.invalid_grade'))
  should validate_numericality_of(:grade_entry_item_id).with_message(I18n.t('invalid_id'))
  should validate_numericality_of(:grade_entry_student_id).with_message(I18n.t('invalid_id'))

  should allow_value(0.0).for(:grade)
  should allow_value(1.5).for(:grade)
  should allow_value(100.0).for(:grade)
  should_not allow_value(-0.5).for(:grade)
  should_not allow_value(-1.0).for(:grade)
  should_not allow_value(-100.0).for(:grade)

  should allow_value(1).for(:grade_entry_item_id)
  should allow_value(2).for(:grade_entry_item_id)
  should allow_value(100).for(:grade_entry_item_id)
  should_not allow_value(0).for(:grade_entry_item_id)
  should_not allow_value(-1).for(:grade_entry_item_id)
  should_not allow_value(-100).for(:grade_entry_item_id)

  should allow_value(1).for(:grade_entry_student_id)
  should allow_value(2).for(:grade_entry_student_id)
  should allow_value(100).for(:grade_entry_student_id)
  should_not allow_value(0).for(:grade_entry_student_id)
  should_not allow_value(-1).for(:grade_entry_student_id)
  should_not allow_value(-100).for(:grade_entry_student_id)
end
