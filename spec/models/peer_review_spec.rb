describe PeerReview do
  it { is_expected.to belong_to(:result) }
  it { is_expected.to belong_to(:reviewer) }

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
