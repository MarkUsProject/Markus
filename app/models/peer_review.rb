require 'set'

class PeerReview < ApplicationRecord
  belongs_to :result
  belongs_to :reviewer, class_name: 'Grouping'

  validates_associated :reviewer
  validates_associated :result
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

  # Deletes a peer review between the reviewer and reviewee groupings,
  # otherwise if none exists returns nil
  def self.delete_peer_review_between(reviewer, reviewee)
    if review_exists_between?(reviewer, reviewee)
      peer_review = reviewer.review_for(reviewee)
      peer_review.destroy
    end
  end

  # Deletes all peer reviewers for the reviewee groupings
  def self.delete_all_peer_reviews_for(reviewee_id)
    PeerReview.joins(result: :submission).where(submissions: { grouping_id: reviewee_id }).delete_all
  end

  def self.assign(reviewer_groups, reviewee_groups)
    reviewer_groups.each do |reviewer_group|
      reviewee_groups.each do |reviewee_group|
        if reviewee_group.current_submission_used.nil?
          raise SubmissionsNotCollectedException
        end
        PeerReview.create_peer_review_between(reviewer_group, reviewee_group)
      end
    end
  end

  def self.unassign(selected_reviewee_group_ids, reviewers_to_remove_from_reviewees_map)
    # First do specific unassigning.
    reviewers_to_remove_from_reviewees_map.each do |reviewee_id, reviewer_id_to_bool|
      reviewer_id_to_bool.each do |reviewer_id, dummy_value|
        reviewee_group = Grouping.find_by_id(reviewee_id)
        reviewer_group = Grouping.find_by_id(reviewer_id)
        PeerReview.delete_peer_review_between(reviewer_group, reviewee_group)
      end
    end

    PeerReview.delete_all_peer_reviews_for(selected_reviewee_group_ids)
  end
end
