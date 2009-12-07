require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

# Tests for GradeEntryStudents
class GradeEntryStudentTest < ActiveSupport::TestCase
  
  should_belong_to :grade_entry_form  
  should_belong_to :user
  
  # Not yet
  #should_have_many :grades
  
  should_validate_numericality_of :grade_entry_form_id, :message => I18n.t('invalid_id')
  should_validate_numericality_of :user_id, :message => I18n.t('invalid_id')
  
  should_allow_values_for :grade_entry_form_id, 1, 2, 100
  should_not_allow_values_for :grade_entry_form_id, 0, -1, -100
  
  should_allow_values_for :user_id, 1, 2, 100
  should_not_allow_values_for :user_id, 0, -1, -100
  
end

