module RandomAssignerHelper
  def perform_random_assignments(assignment, reviewer_groups, reviewee_groups, num_reviews_per_reviewer)
    num_permutations = get_number_of_permutations(num_reviews_per_reviewer)
    permutation_list = []
    debugger
  end

  private
  # Returns the minimum amount of extra permutations needed so the swapping of
  # permutation elements works.
  def get_number_of_permutations(num_reviews_per_reviewer)
    ((@reviewer_groups.size.to_f * num_reviews_per_reviewer / @reviewee_groups.size) + 1.0).to_f
  end
end
