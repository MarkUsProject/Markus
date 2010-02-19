require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

# Tests for Grades
class GradeTest < ActiveSupport::TestCase
  
  # Basic validation tests
  should_belong_to :grade_entry_item
  should_belong_to :grade_entry_student
  
  should_validate_numericality_of :grade, :message => I18n.t('grade_entry_forms.invalid_grade')
  should_validate_numericality_of :grade_entry_item_id, :message => I18n.t('invalid_id')
  should_validate_numericality_of :grade_entry_student_id, :message => I18n.t('invalid_id')
  
  should_allow_values_for :grade, 0.0, 1.5, 100.0
  should_not_allow_values_for :grade, -0.5, -1.0, -100.0;
  
  should_allow_values_for :grade_entry_item_id, 1, 2, 100
  should_not_allow_values_for :grade_entry_item_id, 0, -1, -100
  
  should_allow_values_for :grade_entry_student_id, 1, 2, 100
  should_not_allow_values_for :grade_entry_student_id, 0, -1, -100
  
end
