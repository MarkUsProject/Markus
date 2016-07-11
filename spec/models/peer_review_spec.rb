require 'spec_helper'

describe PeerReview do
  it { is_expected.to validate_presence_of(:result) }
  it { is_expected.to validate_presence_of(:reviewer) }
  it { is_expected.to validate_numericality_of(:reviewer_id) }
  it { is_expected.to validate_numericality_of(:result_id) }
  it { should_not allow_value(-1).for(:result_id) }
  it { should_not allow_value(-59).for(:reviewer_id) }
  it { should allow_value(100).for(:result_id) }
  it { should allow_value(42).for(:reviewer_id) }

  describe 'reviewee integrity' do
    let!(:peer_review) { create(:peer_review) }

    it 'reviewer should not be the reviewee' do
      expect(peer_review.reviewer.id).to_not eq peer_review.reviewee.id
    end

    it 'should have reviewer have a review to others' do
      expect(peer_review.reviewer.peer_reviews_to_others.first.id).to eq peer_review.id
    end
  end

  describe 'peer review assignment' do
    it 'random assigns properly' do
      expect(PeerReview.all.size).to eq 0

      assignment_with_pr = create(:assignment_with_peer_review_and_groupings_results)
      selected_reviewer_group_ids = assignment_with_pr.pr_assignment.groupings.map { |g| g.id }
      selected_reviewee_group_ids = assignment_with_pr.groupings.map(&:id)
      PeerReviewsController.new.perform_random_assignment(assignment_with_pr.pr_assignment, 2,
                                                          selected_reviewer_group_ids, selected_reviewee_group_ids)

      expect(Grouping.all.size).to eq 6
      expect(PeerReview.all.size).to eq 6

      pr_groupings_list = assignment_with_pr.pr_assignment.groupings.to_a
      results_list = assignment_with_pr.groupings.map { |g| g.current_submission_used.get_latest_result }

      # Due to previous expect() verifications, along with schema restraints,
      # and how the factory for the pr assignment is set up, this will hold in
      # testing both proper assignment and forward/backward assignments.
      results_list.each do |result|
        expect(PeerReview.where(result: result).size).to eq 2
      end
    end
  end
end
