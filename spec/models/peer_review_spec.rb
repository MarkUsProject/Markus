describe PeerReview do
  it { is_expected.to belong_to(:result) }
  it { is_expected.to belong_to(:reviewer) }
  let!(:peer_review) { create(:peer_review) }

  describe 'reviewee integrity' do
    it 'reviewer should not be the reviewee' do
      expect(peer_review.reviewer.id).to_not eq peer_review.reviewee.id
    end

    it 'should have reviewer have a review to others' do
      expect(peer_review.reviewer.peer_reviews_to_others.first.id).to eq peer_review.id
    end
  end


  describe 'with a single student reviewee' do
    before :each do
      @grouping1 = create(:grouping)
      @student = create(:student)
      @grouping1.add_member(@student)
      @submission = create(:submission, submission_version_used: true, grouping: @grouping1)
      @grouping1.reload
      @grouping2 = create(:grouping)
    end

    it 'cannot have the same student be a reviewer' do
      @grouping2.add_member(@student)
      expect(PeerReview.can_assign_peer_review_to?(@grouping2, @grouping1)).to be false
    end

    it 'can be assigned a reviewer' do
      expect(PeerReview.create_peer_review_between(@grouping2, @grouping1)).to be
    end

    it 'cannot be assigned the same reviewer twice' do
      PeerReview.create_peer_review_between(@grouping2, @grouping1)
      expect(PeerReview.create_peer_review_between(@grouping2, @grouping1)).to be nil
    end

    describe '#review_exists_between?' do
      it 'returns false for an unassigned reviewer' do
        expect(PeerReview.review_exists_between?(@grouping2, @grouping1)).to be false
      end

      it 'returns true for an assigned reviewer' do
        PeerReview.create_peer_review_between(@grouping2, @grouping1)
        expect(PeerReview.review_exists_between?(@grouping2, @grouping1)).to be
      end
    end
  end
end
