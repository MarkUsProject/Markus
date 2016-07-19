require 'spec_helper'

describe AnnotationCategoriesController do
  describe 'peer review assignment controller' do
    it 'random assigns properly' do
      expect(PeerReview.all.size).to eq 0
      expect(Result.all.size).to eq 0

      assignment_with_pr = create(:assignment_with_peer_review_and_groupings_results)
      selected_reviewer_group_ids = assignment_with_pr.pr_assignment.groupings.map(&:id)
      selected_reviewee_group_ids = assignment_with_pr.groupings.map(&:id)
      PeerReviewsController.new.perform_random_assignment(assignment_with_pr.pr_assignment, 2,
                                                          selected_reviewer_group_ids, selected_reviewee_group_ids)

      expect(Grouping.all.size).to eq 6
      expect(PeerReview.all.size).to eq 6
      expect(PeerReview.where(result: Result.all).size).to eq 6
    end
  end
end
