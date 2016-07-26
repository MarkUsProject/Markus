class SubmissionsNotCollectedException < Exception
end

module PeerReviewHelper
  # Returns a dict of: reviewee_id => [list of reviewer_id's].
  def create_map_reviewee_to_reviewers(reviewer_groups, reviewee_groups)
    reviewer_ids = reviewer_groups.map { |reviewer| reviewer['id'] }
    peer_review_map = Hash.new { |hash, key| hash[key] = [] }
    reviewee_groups.each { |reviewee| peer_review_map[reviewee['id']] }

    PeerReview.includes(result: [submission: [grouping: :group]])
              .where(reviewer_id: reviewer_ids).each do |peer_review|
      reviewee_group_id = peer_review.result.submission.grouping.id
      peer_review_map[reviewee_group_id].push(peer_review.reviewer_id)
    end

    peer_review_map
  end

  # Returns a map of group id => names.
  def create_map_group_id_to_name(reviewer_groups, reviewee_groups)
    # We need to get every possible group so we have a big map of everyone that
    # is present in both tables. This means ids from both the reviewers and the
    # reviewees group, since this data is eligible for use in both tables.
    unique_group_ids = {}
    reviewer_groups.each { |reviewer| unique_group_ids[reviewer['id']] = 0 }
    reviewee_groups.each { |reviewee| unique_group_ids[reviewee['id']] = 0 }

    # Compress into a single list so we can pass it off as a query.
    id_to_group_name_list = []
    unique_group_ids.each do |key, val|
      id_to_group_name_list.push(key)
    end

    # Retrieve all the groups with the unique id list, and map the id => name.
    id_to_group_name_map = {}
    Grouping.includes(:group).where(id: id_to_group_name_list).each do |grouping|
      id_to_group_name_map[grouping.id] = grouping.group.group_name
    end

    return id_to_group_name_map
  end
end
