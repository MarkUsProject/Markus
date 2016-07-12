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
      reviewer_id = pr_grouping.id
      random_group = a1.groupings[Random.rand(a1.groupings.size)]
      if reviewer_id != random_group.id
        reviewee_result = Result.create!(submission: random_group.current_submission_used,
                                         marking_state: Result::MARKING_STATES[:incomplete])
        PeerReview.create(reviewer: pr_grouping, result: reviewee_result)
      end
    end
  end
end
