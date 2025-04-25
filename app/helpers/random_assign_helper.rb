require 'set'

class UnableToRandomlyAssignGroupException < RuntimeError
end

module RandomAssignHelper
  # Performs the random assignment, and stores them in the database.
  # Reviewer/reviewee ids should belong to the assignment provided for this to
  # work correctly.
  # Can throw UnableToRandomlyAssignGroupException if not possible to perform.
  # num_groups is the number of groups each *reviewer* should have assigned
  # at the end of the assignment, including pre-existing peer reviews.
  def perform_random_assignment(pr_assignment, num_groups,
                                reviewer_ids, reviewee_ids)
    # If the caller passes string ids from get_grouping_info,
    # they should be converted.
    reviewer_ids = reviewer_ids.map(&:to_i)
    reviewee_ids = reviewee_ids.map(&:to_i)

    initialize_data_structures(num_groups, reviewer_ids, reviewee_ids)
    create_peer_review_assignments
    save_peer_reviews(pr_assignment)
  end

  private

  def initialize_data_structures(num_groups, reviewer_ids, reviewee_ids)
    # A dictionary mapping reviewer id to a set of reviewee ids.
    @reviewer_to_reviewee_sets = Hash.new { |h, k| h[k] = Set.new }

    # A list of reviewers ids, containing num_groups occurrences for each one.
    @reviewers = reviewer_ids * num_groups

    # A list of reviewee ids, repeated to match the size of @reviewers.
    @reviewees = reviewee_ids * (@reviewers.size.to_f / reviewee_ids.size).ceil

    # A dictionary mapping grouping id to a set of student ids.
    @group_to_students = Hash.new { |h, k| h[k] = Set.new }
    groupings = Grouping.joins(:memberships).joins(memberships: :role)
                        .where(id: reviewer_ids + reviewee_ids,
                               memberships: { type: 'StudentMembership' })
                        .pluck(:id, 'memberships.role_id')
    groupings.each do |grouping_id, student_id|
      @group_to_students[grouping_id].add(student_id)
    end

    # Remove reviewer ids if there are existing peer reviews already assigned
    process_existing_peer_reviews(reviewer_ids, reviewee_ids)

    # Shuffle the reviewees to emulate randomness.
    @reviewees = @reviewees.shuffle.take(@reviewers.size)
  end

  # Remove reviewer id occurrences from @reviewers by how many times they
  # already have existing peer reviews for the given reviewee_ids.
  # If a group already has more than the number of reviews requested,
  # then they won't appear in @reviewers at all.
  #
  # Also add existing peer reviews to @reviewer_to_reviewee_sets.
  def process_existing_peer_reviews(reviewer_ids, reviewee_ids)
    PeerReview.includes(:reviewer,
                        { result: { submission: :grouping } })
              .where(reviewer_id: reviewer_ids, 'groupings.id': reviewee_ids)
              .find_each do |peer_review|
      reviewer_id = peer_review.reviewer_id
      reviewee_id = peer_review.reviewee.id

      @reviewer_to_reviewee_sets[reviewer_id].add(reviewee_id)

      index = @reviewers.find_index(reviewer_id)
      unless index.nil?
        @reviewers.delete_at(index)
      end
      index = @reviewees.find_index(reviewee_id)
      unless index.nil?
        @reviewees.delete_at(index)
      end
    end
  end

  # Updates the data structures so that @reviewers and
  # @reviewees together specify a valid mapping of reviewer to
  # reviewee groups.
  # Or, throws an UnableToRandomlyAssignGroupException if this is not possible.
  def create_peer_review_assignments
    @reviewers.size.times do |curr_index|
      curr_reviewer_id = @reviewers[curr_index]
      was_assigned = false

      # Can't assign to the current index, so we need to advance ahead and wrap
      # around to see if we can do so with others.
      @reviewers.size.times do |i|
        try_index = (curr_index + i) % @reviewers.size
        try_reviewee_id = @reviewees[try_index]

        if can_assign?(curr_reviewer_id, curr_index, try_index)
          if try_index < curr_index
            try_reviewer_id = @reviewers[try_index]
            curr_reviewee_id = @reviewees[curr_index]

            @reviewer_to_reviewee_sets[try_reviewer_id].delete(try_reviewee_id)
            @reviewer_to_reviewee_sets[try_reviewer_id].add(curr_reviewee_id)
          end

          @reviewer_to_reviewee_sets[curr_reviewer_id].add(try_reviewee_id)
          swap(@reviewees, curr_index, try_index)
          was_assigned = true
          break
        end
      end

      # We checked every possibility and no-one previous could swap, and no
      # other matches existed from the shuffle index onward (if it's true).
      raise UnableToRandomlyAssignGroupException unless was_assigned
    end
  end

  # Return whether the given curr_reviewer_id can be assigned to
  # @reviewees[try_index], swapping with any reviewer previously
  # assigned to try_index if necessary.
  def can_assign?(curr_reviewer_id, curr_index, try_index)
    curr_reviewee_id = @reviewees[curr_index]
    try_reviewee_id = @reviewees[try_index]
    try_reviewer_id = @reviewers[try_index]

    if curr_index == try_index
      compatible_groups?(curr_reviewer_id, try_reviewee_id)
    else
      curr_reviewee_id != try_reviewee_id &&
        compatible_groups?(curr_reviewer_id, try_reviewee_id) &&
        # additional checks if there's already a reviewer assigned to try_index
        (try_reviewer_id.nil? ||
          (curr_reviewer_id != try_reviewer_id &&
            compatible_groups?(try_reviewer_id, curr_reviewee_id)))
    end
  end

  # Return whether the groups reviewer_id and reviewee_id are not already
  # paired, and that they do not have any students in common.
  # This means they can be assigned together for a peer review.
  def compatible_groups?(reviewer_id, reviewee_id)
    !is_reviewer_assigned_to?(reviewer_id, reviewee_id) &&
      !groups_share_students?(reviewer_id, reviewee_id)
  end

  def is_reviewer_assigned_to?(reviewer_id, reviewee_id)
    @reviewer_to_reviewee_sets[reviewer_id].member?(reviewee_id)
  end

  def groups_share_students?(group1, group2)
    @group_to_students[group1].intersect?(@group_to_students[group2])
  end

  def swap(arr, i, j)
    arr[i], arr[j] = arr[j], arr[i]
  end

  def save_peer_reviews(pr_assignment)
    return if @reviewers.empty? || @reviewees.empty?

    assignment_criteria = pr_assignment.peer_criteria

    groupings = Grouping.includes(:current_submission_used)
                        .where(id: @reviewees)

    submission_map = groupings.map do |g|
      [g.id, g.current_submission_used.id]
    end.to_h

    now = Time.current
    results = Result.create(
      @reviewees.map do |reviewee_id|
        { submission_id: submission_map[reviewee_id],
          marking_state: Result::MARKING_STATES[:incomplete],
          created_at: now,
          updated_at: now }
      end
    )
    unless assignment_criteria.empty?
      Mark.insert_all(
        results.flat_map do |result|
          assignment_criteria.map do |criterion|
            { result_id: result.id,
              criterion_id: criterion.id,
              created_at: now,
              updated_at: now }
          end
        end
      )
    end

    PeerReview.insert_all(
      results.zip(@reviewers).map do |result, reviewer_id|
        { reviewer_id: reviewer_id, result_id: result.id, created_at: now, updated_at: now }
      end
    )
  end
end
