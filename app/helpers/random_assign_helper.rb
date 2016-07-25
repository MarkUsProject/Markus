require 'set'

class UnableToRandomlyAssignGroupException < Exception
end

module RandomAssignHelper
  # Performs the random assignment, and stores them in the database.
  def perform_random_assignment(pr_assignment, num_groups_for_reviewers, reviewer_ids, reviewee_ids)
    # TODO - need to change away from that function which returns IDs as strings... (database returns ints)
    reviewer_ids = reviewer_ids.map(&:to_i)
    reviewee_ids = reviewee_ids.map(&:to_i)

    initialize_fields
    generate_eligible_reviewers_list(reviewer_ids, num_groups_for_reviewers)

    # NOTE: The following 2 methods depend on 'generate_eligible_reviewers_list'.
    generate_shuffled_reviewees(reviewee_ids)
    generate_assigned_reviewer_to_shuffle_list(num_groups_for_reviewers)

    generate_group_to_students_map(reviewer_ids + reviewee_ids)
    perform_peer_review_assignments
  end

  private
  def is_reviewer_assigned_to?(reviewer_id, reviewee_id)
    @reviewers_already_assigned_to.key?(reviewer_id) && @reviewers_already_assigned_to[reviewer_id].member?(reviewee_id)
  end

  def groups_share_students?(first_group_id, second_group_id)
    @group_to_students[first_group_id].intersect?(@group_to_students[second_group_id])
  end

  def swap_indices(arr, first_index, second_index)
    arr[first_index], arr[second_index] = arr[second_index], arr[first_index]
  end

  def initialize_fields
    @shuffled_reviewees = []
    @reviewers_already_assigned_to = Hash.new { |h, k| h[k] = Set.new }  # reviewer_id => set(reviewee_ids)
  end

  # Creates a list of eligible reviewers, meaning it removes reviewer groups
  # that are not eligible from the list provided... while keeping the ones
  # which need to be assigned.
  def generate_eligible_reviewers_list(selected_reviewer_group_ids, num_groups_for_reviewers)
    @eligible_reviewer_groups = selected_reviewer_group_ids * num_groups_for_reviewers
    PeerReview.where(reviewer_id: selected_reviewer_group_ids).each do |peer_review|
      reviewer_id = peer_review.reviewer_id
      reviewee_id = peer_review.reviewee.id

      # Remember this assignment.
      @reviewers_already_assigned_to[reviewer_id].add(reviewee_id)

      # It might be possible that there have been tons of manual assignments
      # of peer reviews exceeding 'num_groups_for_reviewers', of which this
      # would eventually return nil... so we need to be safe.
      index = @eligible_reviewer_groups.find_index(reviewer_id)
      unless index.nil?
        @eligible_reviewer_groups.delete_at(index)
      end
    end
  end

  # Creates a list of reviewees that is necessary that each reviewer can be
  # assigned the proper amount of reviewees.
  def generate_shuffled_reviewees(selected_reviewee_group_ids)
    num_times_to_add_reviewee = (@eligible_reviewer_groups.size.to_f / selected_reviewee_group_ids.size).ceil
    num_times_to_add_reviewee.times { @shuffled_reviewees += selected_reviewee_group_ids }
    @shuffled_reviewees.shuffle
  end

  # No assignments of reviewers to reviewees exist at the beginning, so the
  # placeholder is nil until a group id is emplaced.
  def generate_assigned_reviewer_to_shuffle_list(num_groups_for_reviewers)
    # TODO - Try to turn into a .map() or something better...
    @assigned_reviewer_to_shuffled_reviewee = []
    (0...@eligible_reviewer_groups.size*num_groups_for_reviewers).each do |dummy|
      @assigned_reviewer_to_shuffled_reviewee.push(nil)
    end
  end

  # Takes the list of group IDs (which should be both reviewers and reviewees)
  # and creates the @group_to_students mapping for quick lookup of students in
  # the group ID.
  def generate_group_to_students_map(group_id_list)
    @group_to_students = Hash.new
    Grouping.includes(:students).where(id: group_id_list).each do |grouping|
      @group_to_students[grouping.id] = Set.new
      grouping.students.each { |student| @group_to_students[grouping.id].add(student.id) }
    end
  end

  def perform_peer_review_assignments
    shuffle_index = 0
    while @eligible_reviewer_groups.any?
      reviewer_id = @eligible_reviewer_groups.pop

      unless attempt_assign_at_index(reviewer_id, shuffle_index) ||
          attempt_assign_forward(reviewer_id, shuffle_index) ||
          attempt_assign_backwards(reviewer_id, shuffle_index)
        raise UnableToRandomlyAssignGroupOptimizedException
      end

      shuffle_index += 1
    end

    create_peer_reviews_in_database
  end

  def can_assign?(reviewer_id, reviewee_id)
    if is_reviewer_assigned_to?(reviewer_id, reviewee_id)
      return false
    end

    if groups_share_students?(reviewer_id, reviewee_id)
      # If they do overlap with students, then we know they are never eligible
      # again, so we should then remember these cannot be assigned to each other.
      @reviewers_already_assigned_to[reviewer_id].add(reviewee_id)
      return false
    end

    true
  end

  def mark_reviewer_assigned_to(reviewer_id, reviewee_id, index)
    @assigned_reviewer_to_shuffled_reviewee[index] = reviewer_id
    @reviewers_already_assigned_to[reviewer_id].add(reviewee_id)
  end

  def unmark_reviewer_assignment(index)
    reviewer_id = @assigned_reviewer_to_shuffled_reviewee[index]
    reviewee_id = @shuffled_reviewees[index]
    @assigned_reviewer_to_shuffled_reviewee[index] = nil
    @reviewers_already_assigned_to[reviewer_id].delete(reviewee_id)
  end

  def attempt_assign_at_index(reviewer_id, shuffle_index)
    reviewee_id = @shuffled_reviewees[shuffle_index]
    if can_assign?(reviewer_id, reviewee_id)
      mark_reviewer_assigned_to(reviewer_id, reviewee_id, shuffle_index)
      return true
    end

    false
  end

  def do_forward_assign_swap_and_mark(reviewer_id, reviewee_id, shuffle_index, swap_index)
    swap_indices(@shuffled_reviewees, shuffle_index, swap_index)
    mark_reviewer_assigned_to(reviewer_id, reviewee_id, shuffle_index)
  end

  def attempt_assign_forward(reviewer_id, shuffle_index)
    (shuffle_index+1...@shuffled_reviewees.size).each do |swap_index|
      reviewee_id = @shuffled_reviewees[swap_index]
      if can_assign?(reviewer_id, reviewee_id)
        do_forward_assign_swap_and_mark(reviewer_id, reviewee_id, shuffle_index, swap_index)
        return true
      end
    end

    false
  end

  def can_assign_to_prev_index?(reviewer_id, prev_index, shuffle_index)
    current_reviewee_id = @shuffled_reviewees[shuffle_index]
    prev_reviewer_id = @assigned_reviewer_to_shuffled_reviewee[prev_index]
    prev_reviewee_id = @shuffled_reviewees[prev_index]

    # We can only backward swap assign if the prev/current reviewee are different,
    # it's not the same group, and if they can be assigned properly after swapping.
    current_reviewee_id != prev_reviewee_id && reviewer_id != prev_reviewer_id &&
        can_assign?(reviewer_id, prev_reviewee_id) && can_assign?(prev_reviewer_id, current_reviewee_id)
  end

  def swap_previous_with_current_and_assign(reviewer_id, prev_index, shuffle_index)
    prev_reviewer_id = @assigned_reviewer_to_shuffled_reviewee[prev_index]

    unmark_reviewer_assignment(prev_index)
    swap_indices(@shuffled_reviewees, prev_index, shuffle_index)
    mark_reviewer_assigned_to(prev_reviewer_id, @shuffled_reviewees[prev_index], prev_index)
    mark_reviewer_assigned_to(reviewer_id, @shuffled_reviewees[shuffle_index], shuffle_index)
  end

  def attempt_assign_backwards(reviewer_id, shuffle_index)
    (0...shuffle_index).each do |prev_index|
      if can_assign_to_prev_index?(reviewer_id, prev_index, shuffle_index)
        swap_previous_with_current_and_assign(reviewer_id, prev_index, shuffle_index)
        return true
      end
    end

    false
  end

  def create_peer_reviews_in_database
    # TODO - Mixing existing reviews causes nil elements in the list due to only needing to assign to a subset...
    (0...@assigned_reviewer_to_shuffled_reviewee.size).each do |i|
      reviewer_id = @assigned_reviewer_to_shuffled_reviewee[i]

      # TODO - Remove this when nils are properly fixed (see above comment)
      # NOTE: Only reason a nil value when we're completely and fully done assigning, so breaking is okay
      # The final version obviously should not have this.
      if reviewer_id.nil?
        break
      end

      reviewee_id = @shuffled_reviewees[i]
      reviewer = Grouping.find(reviewer_id)
      reviewee = Grouping.find(reviewee_id)

      # Debugging:
      PeerReview.create_peer_review_between(reviewer, reviewee)
    end
  end
end
