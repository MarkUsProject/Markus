require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

# Tests for GradeEntryForms
class GradeEntryFormTest < ActiveSupport::TestCase

  # Basic validation tests
  should_have_many :grade_entry_items, :grade_entry_students
  should_validate_presence_of :short_identifier
  should_validate_uniqueness_of :short_identifier, :case_sensitive => :true, 
                                :message => I18n.t('grade_entry_forms.invalid_identifier')
  
  # Dates in the past should also be allowed
  should_allow_values_for :date, 1.day.ago, 1.day.from_now
  should_not_allow_values_for :date, "abcd", "100-10"
  
  # Make sure validate works appropriately when the date is valid
  def test_validate_valid_date
    g = GradeEntryForm.new
    g.short_identifier = "T1"
    g.date = 1.day.from_now
    assert g.valid?
  end     
  
  # Make sure validate works appropriately when the date is invalid
  def test_validate_invalid_date
    g = GradeEntryForm.new
    g.short_identifier = "T1"
    g.date = "2009-"
    assert !g.valid?
  end
  
  # Make sure that validate allows dates to be set in the past
  def test_validate_date_in_the_past
    g = GradeEntryForm.new
    g.short_identifier = "T1"
    g.date = 1.day.ago
    assert g.valid?
  end
end
