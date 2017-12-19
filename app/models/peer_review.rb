require 'set'

class PeerReview < ApplicationRecord
  belongs_to :result
  belongs_to :reviewer, class_name: 'Grouping'

  validates_associated :reviewer
  validates_associated :result
  validates_presence_of :reviewer
  validates_presence_of :result
  validates_numericality_of :reviewer_id, only_integer: true, greater_than: 0
  validates_numericality_of :result_id, only_integer: true, greater_than: 0
  validate :no_students_should_be_reviewer_and_reviewee

  def reviewee
    result.submission.grouping
  end

  def no_students_should_be_reviewer_and_reviewee
    if result and reviewer
      student_id_set = Set.new
      reviewer.students.each { |student| student_id_set.add(student.id) }
      result.submission.grouping.students.each do |student|
        if student_id_set.include?(student.id)
          errors.add(:reviewer_id, I18n.t('peer_review.cannot_allow_reviewer_to_be_reviewee'))
          break
        end
      end
    end
  end

  def self.review_exists_between?(reviewer, reviewee)
    !reviewer.review_for(reviewee).nil?
  end

  def self.can_assign_peer_review_to?(reviewer, reviewee)
    !review_exists_between?(reviewer, reviewee) && reviewer.does_not_share_any_students?(reviewee)
  end

  # Creates a new peer review between the reviewer and reviewee groupings,
  # otherwise if one exists it returns nil
  def self.create_peer_review_between(reviewer, reviewee)
    if can_assign_peer_review_to?(reviewer, reviewee)
      result = Result.create!(submission: reviewee.current_submission_used,
                              marking_state: Result::MARKING_STATES[:incomplete])
      peer_review = PeerReview.create!(reviewer: reviewer, result: result)
      result.peer_review_id = peer_review.id
      result.save!
      return peer_review
    end
  end
end
