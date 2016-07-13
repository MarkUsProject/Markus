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
end
