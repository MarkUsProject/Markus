# NOTE: This has to be run after assignment and group generations since it is
# dependant on groups existing for Assignment 1.

namespace :db do
  desc 'Create peer reviews and related data'
  task :peer_reviews => :environment do
    puts 'Creating A1 Peer Review and updating A1 to have the peer review'
    a1 = Assignment.find_by(short_identifier: 'A1')
    a1.update(has_peer_review: true)  # Creates 'a1pr' via callback.

    a1pr = a1.pr_assignment
    a1pr.clone_groupings_from(a1.id)

    selected_reviewer_group_ids = a1pr.groupings.map { |g| g.id }
    selected_reviewee_group_ids = a1.groupings.map { |g| g.id }

    PeerReviewsController.new.perform_random_assignment(
        a1pr, 3, selected_reviewer_group_ids, selected_reviewee_group_ids)
  end
end
