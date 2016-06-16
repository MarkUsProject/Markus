require 'set'

class RandomAssignmentException < Exception
end

class InvalidMinimumGroupSize < RandomAssignmentException
end

class NotEnoughGroupsToAssignTo < RandomAssignmentException
end

class PeerReviewRandomAssigner
  def initialize(pr_assignment, reviewer_groupings_map, reviewee_groupings_map, num_groups_min)
    if num_groups_min < 1
      raise InvalidMinimumGroupSize
    end

    @pr_assignment = pr_assignment
    @reviewer_groupings_map = reviewer_groupings_map
    @reviewee_groupings_map = reviewee_groupings_map
    @num_groups_min = num_groups_min
  end

  # Assigns everyone from a peer review assignment to have at least the
  # required number of peer review assignments.
  # If this is not possible, it will throw a RandomAssignmentException.
  def randomly_assign_groups
    extract_data_to_fields()
    generate_data_structures()
    generate_assignments()

    # TODO - Return the proper reviewer => result instead of reviewer => reviewee:
    @reviewer_to_reviewee_peer_review_list
  end

  private
  def extract_data_to_fields
    @student_ids_to_reviewer_ids = {}
    @student_ids_to_reviewee_ids = {}
    @reviewer_ids_to_student_ids = {}
    @reviewee_ids_to_student_ids = {}
    @temporary_unreviewable_group_count_pairs = []
    @reviewer_to_reviewee_peer_review_list = []
    @peer_reviews = @pr_assignment.get_peer_reviews()
    @reviewer_ids = @reviewer_groupings_map.map { |reviewer| reviewer['id'] }
    @reviewee_ids = @reviewee_groupings_map.map { |reviewee| reviewee['id'] }

    # TODO - Refactor the two into one by passing a few references to a generic function.
    Grouping.where(id: @reviewer_ids).each do |reviewer_grouping|
      reviewer_grouping.students.each do |student|
        unless @student_ids_to_reviewer_ids.has_key?(student.id)
          @student_ids_to_reviewer_ids[student.id] = Set.new
        end
        unless @reviewer_ids_to_student_ids.has_key?(student.id)
          @reviewer_ids_to_student_ids[reviewer_grouping.id] = Set.new
        end

        @reviewer_ids_to_student_ids[reviewer_grouping.id].add(student.id)
        @student_ids_to_reviewer_ids[student.id].add(reviewer_grouping.id)
      end
    end

    Grouping.where(id: @reviewee_ids).each do |reviewee_grouping|
      reviewee_grouping.students.each do |student|
        unless @student_ids_to_reviewee_ids.has_key?(student.id)
          @student_ids_to_reviewee_ids[student.id] = Set.new
        end
        unless @reviewee_ids_to_student_ids.has_key?(student.id)
          @reviewee_ids_to_student_ids[reviewee_grouping.id] = Set.new
        end

        @reviewee_ids_to_student_ids[reviewee_grouping.id].add(student.id)
        @student_ids_to_reviewee_ids[student.id].add(reviewee_grouping.id)
      end
    end
  end

  def generate_data_structures
    @grouping_id_as_reviewer_count = {}
    @grouping_id_as_reviewee_count = {}
    @grouping_being_reviewed_map = {}  # The map to sets DS (1)
    @grouping_being_reviewed_map_max = 0

    # Add all the groups with a default count of zero.
    @reviewer_ids.each { |reviewer_id| @grouping_id_as_reviewer_count[reviewer_id] = 0 }
    @reviewee_ids.each { |reviewee_id| @grouping_id_as_reviewee_count[reviewee_id] = 0 }

    # Collect all the reviewer/reviewee counts from existing peer reviews.
    @peer_reviews.each do |peer_review|
      @grouping_id_as_reviewer_count[peer_review.reviewer.id] += 1
      @grouping_id_as_reviewee_count[peer_review.reviewee.id] += 1
    end

    @grouping_id_as_reviewee_count.each do |reviewee_id, count|
      unless @grouping_being_reviewed_map.has_key?(count)
        @grouping_being_reviewed_map[count] = Set.new
      end
      @grouping_being_reviewed_map[count].add(reviewee_id)

      if count > @grouping_being_reviewed_map_max
        @grouping_being_reviewed_map_max = count
      end
    end
  end

  def generate_assignments
    @grouping_id_as_reviewer_count.each do |reviewer_id, count|
      if count >= @num_groups_min
        next
      end

      remove_unassignable_groups_for_reviewer(reviewer_id)

      # Since I was told I'm not allowed to use linked lists, the only other
      # solution was to have a map and use the fact that. If you're looking at
      # this and wondering why on earth it's like this, I don't make the calls.
      amount_left_to_assign = @num_groups_min - count
      (0..@grouping_being_reviewed_map_max).each do |review_count_index|
        if amount_left_to_assign <= 0
          break
        end

        while @grouping_being_reviewed_map.has_key?(review_count_index) and amount_left_to_assign > 0
          reviewable_set = @grouping_being_reviewed_map[review_count_index]

          # We're pretending that getting the first element is 'random'. This
          # will no longer be eligible for this set.
          reviewee_id = reviewable_set.first
          reviewable_set.delete(reviewee_id)

          # If the set is empty, destroy it.
          if reviewable_set.size == 0
            @grouping_being_reviewed_map.delete(review_count_index)
          end

          # Remember this as a PeerReview row to make in the future. We don't
          # do it now since we want to save all our collections until the end
          # and do them in one go (so we don't create them, possibly error out
          # and have an unexpected database state).
          @reviewer_to_reviewee_peer_review_list.push([reviewer_id, reviewee_id])

          # Put this group into the temp unassignable list with the incremented counter.
          @temporary_unreviewable_group_count_pairs.push([reviewee_id, review_count_index + 1])

          # Reduce the number of assignments required.
          amount_left_to_assign -= 1
        end
      end

      if amount_left_to_assign > 0
        raise NotEnoughGroupsToAssignTo
      end

      restore_unassignable_groups()
    end
  end

  # Takes a list of all the reviewable groups and removes the ones that should
  # not be eligible into a temporary list.
  def remove_unassignable_groups_for_reviewer(reviewer_id)
    @temporary_unreviewable_group_count_pairs = []

    # Exclude any groups the students are part of
    # TODO

    # Exclude any that are currently being peer reviewed by this group
    # TODO
  end

  def restore_unassignable_groups
    @temporary_unreviewable_group_count_pairs.each do |reviewee_count_list|
      reviewee_id = reviewee_count_list[0]
      count = reviewee_count_list[1]

      unless @grouping_being_reviewed_map.has_key?(count)
        @grouping_being_reviewed_map[count] = Set.new
      end
      @grouping_being_reviewed_map[count].add(reviewee_id)
      @grouping_id_as_reviewee_count[reviewee_id] = count
    end
  end
end
