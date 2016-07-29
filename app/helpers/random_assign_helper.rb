require 'set'

class UnableToRandomlyAssignGroupException < Exception
end

module RandomAssignHelper
  # Performs the random assignment, and stores them in the database.
  # Reviewer/reviewee ids should belong to the assignment provided for this to
  # work correctly.
  # Can throw UnableToRandomlyAssignGroupException if not possible to perform.
  def perform_random_assignment(pr_assignment, num_groups_for_reviewers, reviewer_ids, reviewee_ids)
    @pr_assignment = pr_assignment

    # If the caller passes us in the string ID version from get_grouping_info,
    # it should be converted.
    reviewer_ids = reviewer_ids.map(&:to_i)
    reviewee_ids = reviewee_ids.map(&:to_i)

    initialize_fields_and_generate_data_structures(num_groups_for_reviewers, reviewer_ids, reviewee_ids)
    perform_peer_review_assignment_mapping
    create_peer_reviews_in_database
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

  def initialize_fields_and_generate_data_structures(num_groups_for_reviewers, reviewer_ids, reviewee_ids)
    @reviewers_already_assigned_to = Hash.new { |h, k| h[k] = Set.new }  # reviewer_id => set(reviewee_ids)

    generate_eligible_reviewers_list(reviewer_ids, num_groups_for_reviewers)
    generate_shuffled_reviewees(reviewee_ids)
    generate_empty_assigned_reviewer_to_shuffle_list(num_groups_for_reviewers)
    generate_group_to_students_map(reviewer_ids + reviewee_ids)
  end

  # Creates a list of eligible reviewers, meaning it removes reviewer groups
  # that are not eligible from the list provided... while keeping the ones
  # which need to be assigned.
  def generate_eligible_reviewers_list(selected_reviewer_group_ids, num_groups_for_reviewers)
    # Replicate the eligible reviewers by the amount of times we want them to
    # have 'num_groups_for_reviewers' assignments.
    @eligible_reviewer_groups = selected_reviewer_group_ids * num_groups_for_reviewers

    # Now remove them from the list by how many times they already have existing
    # peer reviews.
    PeerReview.where(reviewer_id: selected_reviewer_group_ids).each do |peer_review|
      reviewer_id = peer_review.reviewer_id
      reviewee_id = peer_review.reviewee.id

      @reviewers_already_assigned_to[reviewer_id].add(reviewee_id)

      # If this group already has > num_groups_for_reviewers, then they won't
      # exist in the list, which is okay since we don't want them to exist in
      # this list if they already have the number of reviews requested.
      index = @eligible_reviewer_groups.find_index(reviewer_id)
      unless index.nil?
        @eligible_reviewer_groups.delete_at(index)
      end
    end
  end

  # Creates a list of reviewees that is necessary that each reviewer can be
  # assigned the proper amount of reviewees.
  def generate_shuffled_reviewees(selected_reviewee_group_ids)
    @shuffled_reviewees = []
    num_times_to_add_reviewee = (@eligible_reviewer_groups.size.to_f / selected_reviewee_group_ids.size).ceil
    num_times_to_add_reviewee.times { @shuffled_reviewees += selected_reviewee_group_ids }
    @shuffled_reviewees.shuffle
  end

  # No assignments of reviewers to reviewees exist at the beginning, so the
  # placeholder is nil until a group id is emplaced.
  def generate_empty_assigned_reviewer_to_shuffle_list(num_groups_for_reviewers)
    amount = @eligible_reviewer_groups.size
    @assigned_reviewer_to_shuffled_reviewee = (0...amount).map { nil }
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

  # Updates the data structures so that @assigned_reviewer_to_shuffled_reviewee
  # contains the correct mapping of reviewer to reviewee groups allows creation
  # of peer reviews, or throws an UnableToRandomlyAssignGroupException if it is
  # not possible.
  def perform_peer_review_assignment_mapping
    shuffle_index = 0

    while @eligible_reviewer_groups.any?
      reviewer_id = @eligible_reviewer_groups.pop

      # Attempt to assign at shuffle index.
      was_assigned = attempt_assign_at_index(reviewer_id, shuffle_index)

      # Can't assign to the current index, so we need to advance ahead and wrap
      # around to see if we can do so with others.
      unless was_assigned
        advanced_shuffle_index = (shuffle_index + 1) % @assigned_reviewer_to_shuffled_reviewee.size

        # Keep look forward and backwards until we assign, or run out of reviewees.
        while !was_assigned && advanced_shuffle_index != shuffle_index
          if advanced_shuffle_index > shuffle_index
            was_assigned = attempt_assign_forward_swap(reviewer_id, shuffle_index, advanced_shuffle_index)
          elsif advanced_shuffle_index < shuffle_index
            was_assigned = attempt_assign_backward_swap(reviewer_id, shuffle_index, advanced_shuffle_index)
          end

          advanced_shuffle_index = (advanced_shuffle_index + 1) % @assigned_reviewer_to_shuffled_reviewee.size
        end

        # We checked every possibility and no-one previous could swap, and no
        # other matches existed from the shuffle index onward (if it's true).
        unless was_assigned
          raise UnableToRandomlyAssignGroupException
        end
      end

      shuffle_index += 1
    end
  end

  def can_assign?(reviewer_id, reviewee_id)
    !(is_reviewer_assigned_to?(reviewer_id, reviewee_id) || groups_share_students?(reviewer_id, reviewee_id))
  end

  # Marking here means to map them to each other so we know they are to be
  # assigned, and that we shouldn't try to assign these to each other again.
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

  def attempt_assign_forward_swap(reviewer_id, shuffle_index, advanced_shuffle_index)
    reviewee_id = @shuffled_reviewees[advanced_shuffle_index]

    if can_assign?(reviewer_id, reviewee_id)
      do_forward_assign_swap_and_mark(reviewer_id, reviewee_id, shuffle_index, advanced_shuffle_index)
      return true
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

  def attempt_assign_backward_swap(reviewer_id, shuffle_index, advanced_shuffle_index)
    if can_assign_to_prev_index?(reviewer_id, advanced_shuffle_index, shuffle_index)
      swap_previous_with_current_and_assign(reviewer_id, advanced_shuffle_index, shuffle_index)
      return true
    end

    false
  end

  def create_peer_reviews_in_database
    peer_reviews_reviewer_result = []
    peer_reviews = []
    results = []
    marks = []

    assignment_criteria = @pr_assignment.parent_assignment.get_criteria(:ta)

    # Generate the objects to be added before we start doing mass commits, and
    # also remember them so we can attach them to a new peer review.
    (0...@assigned_reviewer_to_shuffled_reviewee.size).each do |i|
      reviewer_id = @assigned_reviewer_to_shuffled_reviewee[i]

      reviewee_id = @shuffled_reviewees[i]
      reviewer = Grouping.find(reviewer_id)
      reviewee = Grouping.find(reviewee_id)

      result = Result.new(submission: reviewee.current_submission_used,
                          marking_state: Result::MARKING_STATES[:incomplete])
      results << result
      assignment_criteria.each { |criterion| marks << criterion.marks.new(result: result) }
      peer_reviews_reviewer_result << [reviewer, result]
    end

    Result.import results, validate: false
    Mark.import marks, validate: false

    # Peer reviews require IDs to have been made, so they come last.
    peer_reviews_reviewer_result.each do |prdata|
      peer_review = PeerReview.new(reviewer: prdata[0], result: prdata[1])
      peer_reviews << peer_review
    end

    PeerReview.import peer_reviews, validate: false
  end
end
