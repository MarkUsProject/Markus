require 'set'

class PeerReview < ApplicationRecord
  belongs_to :result, dependent: :destroy
  belongs_to :reviewer, class_name: 'Grouping', inverse_of: :peer_reviews_to_others
  has_one :reviewee, class_name: 'Grouping', through: :result, source: :grouping
  validates_associated :reviewer
  validates_associated :result
  validate :no_students_should_be_reviewer_and_reviewee
  has_one :course, through: :result
  validate :assignments_should_match
  before_destroy :check_marks_or_annotations

  def no_students_should_be_reviewer_and_reviewee
    if result && reviewer
      student_id_set = Set.new
      reviewer.students.each { |student| student_id_set.add(student.id) }
      result.submission.grouping.students.each do |student|
        if student_id_set.include?(student.id)
          errors.add(:reviewer_id, :cannot_allow_reviewer_to_be_reviewee)
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
      result.save!
      peer_review
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

  def self.unassign(reviewers_to_remove_from_reviewees_map)
    deleted_count = 0
    undeleted_reviews = []

    # First do specific unassigning.
    reviewers_to_remove_from_reviewees_map.each do |reviewee_id, reviewer_id_to_bool|
      reviewer_id_to_bool.each_key do |reviewer_id|
        reviewee_group = Grouping.find_by(id: reviewee_id)
        reviewer_group = Grouping.find_by(id: reviewer_id)

        unless reviewee_group.nil? || reviewer_group.nil?
          peer_review = reviewer_group.review_for(reviewee_group)
          unless peer_review.nil?
            if self.delete_peer_review_between(reviewer_group, reviewee_group)
              deleted_count += 1
            else
              undeleted_reviews.append(I18n.t('activerecord.models.peer_review.reviewer_assigned_to_reviewee',
                                              reviewer_group_name: reviewer_group.get_group_name,
                                              reviewee_group_name: reviewee_group.get_group_name))
            end
          end
        end
      end
    end
    [deleted_count, undeleted_reviews]
  end

  def check_marks_or_annotations
    if self.has_marks_or_annotations?
      throw(:abort)
    end
  end

  def has_marks_or_annotations?
    result = self.result
    marks_not_nil = result
                    .marks.where.not(mark: nil).exists?
    result.marking_state == Result::MARKING_STATES[:complete] || marks_not_nil || result.annotations.exists?
  end

  def self.get_num_collected(reviewer_group)
    Grouping.joins(peer_reviews: :reviewee)
            .where('peer_reviews.reviewer_id': reviewer_group,
                   'reviewees_peer_reviews.is_collected': true) # "groupings" aliased to "reviewees_peer_reviews"
            .count
  end

  def self.get_num_marked(reviewer_group)
    self.includes(:result, :reviewer).where(reviewer_id: reviewer_group).count do |pr|
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
    mappings.group_by { |x| x[0] }.transform_values { |pairs| pairs.pluck(1) }
  end

  def self.from_csv(assignment, data)
    reviewer_map = assignment.groupings.includes(:group).index_by { |g| g.group.group_name }
    reviewee_map = assignment.parent_assignment.groupings.includes(:group).index_by { |g| g.group.group_name }
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

  private

  def assignments_should_match
    return if result.nil? || reviewer.nil?
    unless result.submission.grouping.assignment == reviewer.assignment.parent_assignment
      errors.add(:base, :not_in_same_assignment)
    end
  end
end
