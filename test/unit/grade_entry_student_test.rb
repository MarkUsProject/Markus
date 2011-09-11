require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

# Tests for GradeEntryStudents
class GradeEntryStudentTest < ActiveSupport::TestCase
  should belong_to :grade_entry_form
  should belong_to :user

  # Not yet
  #should have_many :grades

  should validate_numericality_of(:grade_entry_form_id).with_message(I18n.t('invalid_id'))
  should validate_numericality_of(:user_id).with_message(I18n.t('invalid_id'))

  should allow_value(1).for(:grade_entry_form_id)
  should allow_value(2).for(:grade_entry_form_id)
  should allow_value(100).for(:grade_entry_form_id)
  should_not allow_value(0).for(:grade_entry_form_id)
  should_not allow_value(-1).for(:grade_entry_form_id)
  should_not allow_value(-100).for(:grade_entry_form_id)

  should allow_value(1).for(:user_id)
  should allow_value(2).for(:user_id)
  should allow_value(100).for(:user_id)
  should_not allow_value(0).for(:user_id)
  should_not allow_value(-1).for(:user_id)
  should_not allow_value(-100).for(:user_id)

end

