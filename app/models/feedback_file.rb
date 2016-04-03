class FeedbackFile < ActiveRecord::Base
  belongs_to :submission
  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid
  validates_presence_of :filename # we need a filename
  validates_presence_of :mime_type # we need a mime type
  validates_presence_of :file_content # we need some content

  # === Description
  # Updates the file_content attribute of a feedback file object
  #=== Returns
  # True if saving with the new content succeeds, false otherwise
  def update_file_content(new_content)
    return false if new_content.nil?
    self.file_content = new_content
    self.save
  end
end
