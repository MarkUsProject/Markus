describe PeerReview do
  it { is_expected.to belong_to(:result) }
  it { is_expected.to belong_to(:reviewer) }
  it { is_expected.to have_one(:course) }
  let!(:peer_review) { create(:peer_review) }

  describe 'reviewee integrity' do
    it 'reviewer should not be the reviewee' do
      expect(peer_review.reviewer.id).to_not eq peer_review.reviewee.id
    end

    it 'should have reviewer have a review to others' do
      expect(peer_review.reviewer.peer_reviews_to_others.first.id).to eq peer_review.id
    end
  end

  it 'should not allow associations to belong to different assignments' do
    result = create(:complete_result)
    reviewer = create(:grouping, assignment: create(:assignment))
    expect(build(:peer_review, result: result, reviewer: reviewer)).not_to be_valid
  end

  describe 'with a single student reviewee' do
    let(:assignment) { create(:assignment_with_peer_review) }
    before :each do
      @grouping1 = create(:grouping, assignment: assignment)
      @student = create(:student)
      @grouping1.add_member(@student)
      @submission = create(:submission, submission_version_used: true, grouping: @grouping1)
      @grouping1.reload
      @grouping2 = create(:grouping, assignment: @grouping1.assignment.pr_assignment)
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

  describe '#get_num_collected & #get_num_marked' do
    let(:assignment) { create(:assignment_with_peer_review) }
    let(:student) { create(:student) }
    let(:grouping1) do
      create(:grouping_with_inviter_and_submission,
             inviter: student, assignment: assignment.pr_assignment, is_collected: true)
    end
    let(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: assignment, is_collected: true) }
    let(:grouping3) { create(:grouping_with_inviter_and_submission, assignment: assignment, is_collected: true) }
    let(:grouping4) { create(:grouping_with_inviter_and_submission, assignment: assignment, is_collected: false) }
    let!(:peer_review1) { create(:peer_review, reviewer_id: grouping1.id, result_id: grouping2.current_result.id) }
    let!(:peer_review2) { create(:peer_review, reviewer_id: grouping1.id, result_id: grouping3.current_result.id) }
    let!(:peer_review3) { create(:peer_review, reviewer_id: grouping1.id, result_id: grouping4.current_result.id) }
    context '#get_num_collected' do
      it 'should return no of collected submissions' do
        expect(PeerReview.get_num_collected(grouping1.id)).to eq(2)
      end
    end
    context '#get_num_marked' do
      before do
        grouping2.current_result.update(marking_state: Result::MARKING_STATES[:complete])
        grouping2.reload
      end
      it 'should return no of marked submissions which are collected' do
        expect(PeerReview.get_num_marked(grouping1.id)).to eq(1)
      end
    end
  end
end
