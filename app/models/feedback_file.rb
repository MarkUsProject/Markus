# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: feedback_files
#
#  id                   :integer          not null, primary key
#  file_content         :binary           not null
#  filename             :string           not null
#  mime_type            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  submission_id        :integer
#  test_group_result_id :bigint
#
# Indexes
#
#  index_feedback_files_on_submission_id         (submission_id)
#  index_feedback_files_on_test_group_result_id  (test_group_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#  fk_rails_...  (test_group_result_id => test_group_results.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class FeedbackFile < ApplicationRecord
  belongs_to :submission, optional: true
  belongs_to :test_group_result, optional: true

  validates :submission_id, presence: { if: -> { test_group_result_id.nil? } }

  validates :filename, presence: true # we need a filename
  validates :mime_type, presence: true # we need a mime type
  validates :file_content, presence: true # we need some content
  validate :courses_should_match

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

  def course
    self.submission&.course || self.test_group_result&.course
  end
end
