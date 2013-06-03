class TestResult < ActiveRecord::Base
  belongs_to :submission
  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid

  #=== Description
  # Updates the file_content attribute of an TestResult object
  #=== Returns
  # True if saving with the new content succeeds, false otherwise
  def update_file_content(new_content)
    return false if new_content.nil?
    self.file_content = new_content
    self.save
  end
end
