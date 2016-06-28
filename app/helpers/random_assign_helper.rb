require 'set'

class UnableToRandomlyAssignGroupException < Exception
end

module RandomAssignHelper
  # Performs the random assignment, and stores them in the database.
  # - pr_assignment: The peer review assignment.
  # - num_groups_for_reviewers: How many PR's each group in reviewer_groups should have.
  def perform_random_assignment(pr_assignment, num_groups_for_reviewers)
    @eligible_reviewers = []
    @shuffled_reviewees = []
    @shuffled_reviewees_assigned_reviewers = []
    @num_groups_for_reviewers = num_groups_for_reviewers
    @reviewer_ids_assigned_reviewee_ids_map = Hash.new { |h, k| h[k] = Set.new }

    reviewer_groups_relation = pr_assignment.valid_groupings
    reviewee_groups_relation = pr_assignment.parent_assignment.valid_groupings
    reviewer_groups_relation.each { |reviewer| @eligible_reviewers.push(reviewer) }

    generate_shuffled_reviewees(reviewer_groups_relation, reviewee_groups_relation)
    populate_from_existing_peer_reviews(pr_assignment)
    perform_assignments()
  end

  private
  # Make sure there's enough reviewee groups in the following list such that
  # we have enough repeats of 'reviewee_groups' that we can assign every
  # reviewer group at least 'num_groups_for_reviewers' groups.
  def generate_shuffled_reviewees(reviewer_groups, reviewee_groups)
    num_times_to_add_reviewee = (reviewer_groups.size.to_f * @num_groups_for_reviewers / reviewer_groups.size).ceil
    num_times_to_add_reviewee.times { @shuffled_reviewees += reviewee_groups }
    @shuffled_reviewees.shuffle()

    @shuffled_reviewees_assigned_reviewers = @shuffled_reviewees.map { nil }
  end

  # We need to get all the existing peer reviews for assignments so we can
  # skip some assignments if they exist.
  def populate_from_existing_peer_reviews(pr_assignment)
    pr_assignment.parent_assignment.peer_reviews.each do |peer_review|
      reviewee = peer_review.reviewee
      @reviewer_ids_assigned_reviewee_ids_map[peer_review.reviewer.id].add(reviewee.id)
      remove_reviewee_once_from_shuffled_list(reviewee)
    end
  end

  # Required so that existing reviews don't cause a lopsided distribution.
  def remove_reviewee_once_from_shuffled_list(reviewee)
    index = @shuffled_reviewees.find_index(reviewee)
    @shuffled_reviewees.delete_at(index)
    @shuffled_reviewees_assigned_reviewers.pop()
  end

  def perform_assignments
    shuffle_index = 0
    remove_ineligible_reviewers()

    while @eligible_reviewers.any?
      @eligible_reviewers.each do |reviewer|
        reviewee = get_next_reviewee_from_forward_search(reviewer, shuffle_index)

        # A nil reviewee means we could not find one going forwards, and if so,
        # then try going backwards through assignments (failure will throw).
        if not reviewee.nil?
          add_peer_review_to_db_and_remember_assignment(reviewer, reviewee, shuffle_index)
        else
          find_and_swap_with_group_or_throw(reviewer, shuffle_index)
        end

        shuffle_index += 1
      end

      remove_ineligible_reviewers()
    end
  end

  def remove_ineligible_reviewers
    @eligible_reviewers.delete_if do |reviewer|
      @reviewer_ids_assigned_reviewee_ids_map[reviewer.id].size >= @num_groups_for_reviewers
    end
  end

  # Note: This returns nil if forward searching failed (signal to the caller).
  def get_next_reviewee_from_forward_search(reviewer, shuffle_index)
    # First, check if the current index provided works.
    potential_reviewee = @shuffled_reviewees[shuffle_index]
    if eligible_to_be_assigned(reviewer, potential_reviewee)
      return potential_reviewee
    end

    # Since the index doesnt work, look at the next element until the end of
    # the list, and swap if we find a working group.
    ((shuffle_index + 1)...@shuffled_reviewees.size).each do |new_shuffle_index|
      potential_reviewee = @shuffled_reviewees[new_shuffle_index]
      if eligible_to_be_assigned(reviewer, potential_reviewee)
        swap_shuffled_indices(shuffle_index, new_shuffle_index)
        return potential_reviewee
      end
    end

    nil
  end

  def eligible_to_be_assigned(reviewer, reviewee)
    # If they already have an assignment to the group, it's not viable.
    if @reviewer_ids_assigned_reviewee_ids_map.has_key?(reviewer.id) and
          @reviewer_ids_assigned_reviewee_ids_map[reviewer.id].member?(reviewee.id)
      return false
    end

    # Since they're not assigned, the returned boolean is if they don't share students.
    reviewer.does_not_share_any_students?(reviewee)
  end

  def swap_shuffled_indices(first_index, second_index)
    @shuffled_reviewees[first_index], @shuffled_reviewees[second_index] =
        @shuffled_reviewees[second_index], @shuffled_reviewees[first_index]
  end

  def add_peer_review_to_db_and_remember_assignment(reviewer, reviewee, shuffle_index)
    result = reviewee.current_submission_used.get_latest_result
    PeerReview.create!(reviewer: reviewer, result: result)

    @reviewer_ids_assigned_reviewee_ids_map[reviewer.id].add(reviewee.id)
    @shuffled_reviewees_assigned_reviewers[shuffle_index] = reviewer
  end

  # Goes forward from shuffle_index + 1 constantly ahead and either swaps on
  # finding an eligible reviewee from wrap-around (uses modulus) or throws
  # an UnableToRandomlyAssignGroupException.
  def find_and_swap_with_group_or_throw(reviewer, shuffle_index)
    next_index = 0
    reviewee_at_shuffle_index = @shuffled_reviewees[shuffle_index]
    while next_index < shuffle_index
      reviewee_at_previous_index = @shuffled_reviewees[next_index]
      reviewer_assigned_to_previous_reviewee = @shuffled_reviewees_assigned_reviewers[next_index]

      unless eligible_to_be_assigned(reviewer, reviewee_at_previous_index) and
             eligible_to_be_assigned(reviewer_assigned_to_previous_reviewee, reviewee_at_shuffle_index)
        next_index = (next_index + 1) % @shuffled_reviewees.size
        next
      end

      perform_group_exchange(reviewer, shuffle_index, next_index)
      return
    end

    raise UnableToRandomlyAssignGroupException
  end

  def perform_group_exchange(reviewer, shuffle_index, prev_shuffle_index)
    reviewee_at_shuffle_index = @shuffled_reviewees[shuffle_index]
    reviewee_at_previous_index = @shuffled_reviewees[prev_shuffle_index]
    reviewer_for_prev_reviewee = @shuffled_reviewees_assigned_reviewers[prev_shuffle_index]

    unlink_and_delete_previous_peer_review_assignment(reviewer_for_prev_reviewee, reviewee_at_previous_index)
    swap_shuffled_indices(prev_shuffle_index, shuffle_index)

    add_peer_review_to_db_and_remember_assignment(reviewer, reviewee_at_previous_index, shuffle_index)
    add_peer_review_to_db_and_remember_assignment(reviewer_for_prev_reviewee, reviewee_at_shuffle_index, prev_shuffle_index)
  end

  def unlink_and_delete_previous_peer_review_assignment(reviewer, reviewee)
    result = reviewee.current_submission_used.get_latest_result
    PeerReview.where(reviewer: reviewer, result: result).destroy_all

    @reviewer_ids_assigned_reviewee_ids_map[reviewer.id].delete(reviewee.id)
  end
end
