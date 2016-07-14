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

    a1pr.groupings.each do |pr_grouping|
      random_group = a1.groupings[Random.rand(a1.groupings.size)]
      if pr_grouping.does_not_share_any_students?(random_group)
        PeerReview.create_peer_review_between(pr_grouping, random_group)
      end
    end
  end
end
