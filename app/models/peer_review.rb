require 'set'

class PeerReview < ApplicationRecord
  belongs_to :result, dependent: :destroy
  belongs_to :reviewer, class_name: 'Grouping'
  has_one :reviewee, class_name: 'Grouping', through: :result, source: :grouping
  validates_associated :reviewer
  validates_associated :result
  validate :no_students_should_be_reviewer_and_reviewee

  def no_students_should_be_reviewer_and_reviewee
    if result and reviewer
      student_id_set = Set.new
      reviewer.students.each { |student| student_id_set.add(student.id) }
      result.submission.grouping.students.each do |student|
        if student_id_set.include?(student.id)
          errors.add(:reviewer_id, I18n.t('peer_reviews.errors.cannot_allow_reviewer_to_be_reviewee'))
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
    self.joins(result: :submission).where(submissions: { grouping_id: reviewee_id }).destroy_all
  end

  def self.assign(reviewer_groups, reviewee_groups)
    reviewer_groups.each do |reviewer_group|
      reviewee_groups.each do |reviewee_group|
        if reviewee_group.current_submission_used.nil?
          raise SubmissionsNotCollectedException
        end
        self.create_peer_review_between(reviewer_group, reviewee_group)
      end
    end
  end

  def self.unassign(selected_reviewee_group_ids, reviewers_to_remove_from_reviewees_map)
    # First do specific unassigning.
    reviewers_to_remove_from_reviewees_map.each do |reviewee_id, reviewer_id_to_bool|
      reviewer_id_to_bool.each do |reviewer_id, dummy_value|
        reviewee_group = Grouping.find_by_id(reviewee_id)
        reviewer_group = Grouping.find_by_id(reviewer_id)
        self.delete_peer_review_between(reviewer_group, reviewee_group)
      end
    end

    self.delete_all_peer_reviews_for(selected_reviewee_group_ids)
  end

  def self.get_num_assigned(reviewer_group)
    self.where(reviewer_id: reviewer_group).size
  end

  def self.get_num_marked(reviewer_group)
    self.includes(:result).where(reviewer_id: reviewer_group).count do |pr|
      pr.result.marking_state == Result::MARKING_STATES[:complete]
    end
  end

  def self.get_mappings_for(assignment)
    # NOTE: 'groups' is reviewer group table, 'groups_groupings' is reviewee group table.
    mappings = assignment.pr_peer_reviews
                         .joins(reviewer: :group, reviewee: :group)
                         .order('groups_groupings.group_name', 'groups.group_name')
                         .pluck('groups_groupings.group_name', 'groups.group_name')

    # Group by reviewee group name, and map to just the reviewer group names.
    mappings.group_by { |x| x[0] }.transform_values { |pairs| pairs.map { |p| p[1] } }
  end

  def self.from_csv(assignment, data)
    reviewer_map = Hash[
      assignment.groupings.includes(:group).map { |g| [g.group.group_name, g] }
    ]
    reviewee_map = Hash[
      assignment.parent_assignment.groupings.includes(:group).map { |g| [g.group.group_name, g] }
    ]
    MarkusCsv.parse(data) do |row|
      raise CsvInvalidLineError if row.size < 2
      reviewee = reviewee_map[row.first]
      next if reviewee.nil?
      row.shift # Drop the reviewer, the rest are reviewees and makes iteration easier.
      row.each do |reviewer_group_name|
        reviewer = reviewer_map[reviewer_group_name]
        next if reviewer.nil?
        PeerReview.create_peer_review_between(reviewer, reviewee)
      end
    end
  end
end
