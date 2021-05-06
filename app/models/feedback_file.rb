class FeedbackFile < ApplicationRecord
  belongs_to :submission, optional: true
  belongs_to :test_group_result, optional: true

  validates_presence_of :submission_id, if: -> { test_group_result_id.nil? }

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

  # Returns the associated grouping for this feedback file
  def grouping
    if submission_id.nil?
      test_group_result.test_run.grouping
    else
      submission.grouping
    end
  end
end
