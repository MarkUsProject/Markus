# NOTE: The assignment cannot be generated in the assignments rake task since
# it causes errors to occur. I guess this is due to it not being populated
# properly and something errors out. Therefore, all the peer review stuff is
# done here, including but not limited to creating the PR assignment.

namespace :db do
  desc 'Create peer reviews and related data'
  task :peer_reviews => :environment do
    puts 'Creating A1 Peer Review and updating A1 to have the peer review'
    a1 = Assignment.find_by(short_identifier: 'A1')
    a1.has_peer_review = true  # Creates 'a1pr' via callback.
    a1.save

    a1pr = Assignment.find_by(short_identifier: a1.short_identifier + '_pr')
    a1pr.clone_groupings_from(a1.id)

    # TODO - Make a proper class for this so the code is clearer? Rather than some arbitrary list index?
    # Populate a list of 'list of [group_id, result]'.
    list_of_list_of_results_group_id = []
    a1.groupings.each do |grouping|
      result = grouping.current_submission_used.get_latest_result
      list_of_list_of_results_group_id.push([result, grouping.id])
    end

    # Randomly assign them by modding a random number with the list index.
    # Refuse to take one where the group would review itself.
    a1pr.groupings.each do |pr_grouping|
      index = Random.rand(list_of_list_of_results_group_id.size)
      reviewee_result = list_of_list_of_results_group_id[index][0]
      grouping_id = list_of_list_of_results_group_id[index][1]
      if grouping_id != pr_grouping.id
        PeerReview.create(reviewer: pr_grouping, result: reviewee_result)
      end
    end
  end
end
