# NOTE: This has to be run after assignment and group generations since it is
# dependant on groups existing for Assignment 1.

namespace :db do
  desc 'Create peer reviews and related data'
  task :peer_reviews => :environment do
    puts 'Creating A1 Peer Review and updating A1 to have the peer review'
    a1 = Assignment.find_by(short_identifier: 'A1')
    a1.update(has_peer_review: true)  # Creates 'a1pr' via callback.

    # The group names must not be closed, doing a1pr.clone_groupings_from(a1.id)
    # causes the group names to be identical and then the CSV uploading for the
    # seeding will not work due to ambiguous conflicts.
    a1pr = a1.pr_assignment
    students = Student.all
    15.times do |time|
      student = students[time]
      group = Group.create(group_name: "#{ student.user_name } #{ a1pr.short_identifier }")
      grouping = Grouping.create(group: group, assignment: a1pr)
      grouping.invite([student.user_name], StudentMembership::STATUSES[:inviter], invoked_by_admin = true)
    end

    a1pr.groupings.each do |pr_grouping|
      reviewer_id = pr_grouping.id
      random_group = a1.groupings[Random.rand(a1.groupings.size)]
      if reviewer_id != random_group.id
        reviewee_result = random_group.current_submission_used.get_latest_result
        PeerReview.create(reviewer: pr_grouping, result: reviewee_result)
      end
    end
  end
end
