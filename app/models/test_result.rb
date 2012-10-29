class TestResult < ActiveRecord::Base
  belongs_to :submission

  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid
  validates :completion_status, :presence => true
  validates :assignment, :presence => true
  validates :test_script, :presence => true
  validates :marks_earned, :presence => true
  validates :input_description, :presence => true
  validates :actual_output, :presence => true
  validates :expected_output, :presence => true


  #=== Description
  # Updates the file_content attribute of an TestResult object
  #=== Returns
  # True if saving with the new content succeeds, false otherwise
  def update_file_content(new_content)
    return false if new_content.nil?
    self.file_content = new_content
    return self.save
  end
end
