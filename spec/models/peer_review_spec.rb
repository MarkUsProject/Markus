describe PeerReview do
  let!(:peer_review) { create(:peer_review) }

  it { is_expected.to belong_to(:result) }
  it { is_expected.to belong_to(:reviewer) }
  it { is_expected.to have_one(:course) }

  describe 'reviewee integrity' do
    it 'reviewer should not be the reviewee' do
      expect(peer_review.reviewer.id).not_to eq peer_review.reviewee.id
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

    before do
      @grouping1 = create(:grouping, assignment: assignment)
      @student = create(:student)
      @grouping1.add_member(@student)
      @submission = create(:submission, submission_version_used: true, grouping: @grouping1)
      @grouping1.reload
      @grouping2 = create(:grouping, assignment: @grouping1.assignment.pr_assignment)
    end

    it 'can be assigned a reviewer' do
      expect(PeerReview.create_peer_review_between(@grouping2, @grouping1)).not_to be_nil
    end

    it 'cannot be assigned the same reviewer twice' do
      PeerReview.create_peer_review_between(@grouping2, @grouping1)
      expect(PeerReview.create_peer_review_between(@grouping2, @grouping1)).to be_nil
    end

    describe '#review_exists_between?' do
      it 'returns false for an unassigned reviewer' do
        expect(PeerReview.review_exists_between?(@grouping2, @grouping1)).to be false
      end

      it 'returns true for an assigned reviewer' do
        PeerReview.create_peer_review_between(@grouping2, @grouping1)
        expect(PeerReview.review_exists_between?(@grouping2, @grouping1)).not_to be_nil
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

    before do
      [grouping2, grouping3, grouping4].each do |g|
        create(:peer_review, reviewer_id: grouping1.id, result_id: g.current_result.id)
      end
    end

    describe '#get_num_collected' do
      it 'should return no of collected submissions' do
        expect(PeerReview.get_num_collected(grouping1.id)).to eq(2)
      end
    end

    describe '#get_num_marked' do
      before do
        grouping2.current_result.update(marking_state: Result::MARKING_STATES[:complete])
        grouping2.reload
      end

      it 'should return no of marked submissions which are collected' do
        expect(PeerReview.get_num_marked(grouping1.id)).to eq(1)
      end
    end
  end

  describe 'has_marks_or_annotations?' do
    let(:assignment) { create(:assignment_with_peer_review) }
    let(:peer_review_assignment) { assignment.pr_assignment } # Peer review assignment
    let(:grouping_reviewer) { create(:grouping_with_inviter_and_submission, assignment: peer_review_assignment) }
    let(:grouping_reviewee) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
    let(:peer_review) do
      create(:peer_review, reviewer_id: grouping_reviewer.id, result_id: grouping_reviewee.current_result.id)
    end

    context 'when there are non-zero marks' do
      before do
        criterion = create(:rubric_criterion, assignment: assignment.pr_assignment)
        create(:mark, criterion: criterion, result: peer_review.result, mark: 2.5)
      end

      it 'returns true' do
        expect(peer_review.has_marks_or_annotations?).to be true
      end
    end

    context 'when there are annotations' do
      before do
        create(:text_annotation, result: peer_review.result)
      end

      it 'returns true' do
        expect(peer_review.has_marks_or_annotations?).to be true
      end
    end

    context 'when the assignment is set to complete' do
      before do
        peer_review.result.update(marking_state: Result::MARKING_STATES[:complete])
      end

      it 'returns true' do
        expect(peer_review.has_marks_or_annotations?).to be true
      end
    end

    context 'when there are no marks or annotations' do
      it 'returns false' do
        expect(peer_review.has_marks_or_annotations?).to be false
      end
    end
  end

  describe 'check_marks_or_annotations' do
    let(:assignment) { create(:assignment_with_peer_review) }
    let(:peer_review_assignment) { assignment.pr_assignment } # Peer review assignment
    let(:grouping_reviewer) { create(:grouping_with_inviter_and_submission, assignment: peer_review_assignment) }
    let(:grouping_reviewee) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
    let(:peer_review) do
      create(:peer_review, reviewer_id: grouping_reviewer.id, result_id: grouping_reviewee.current_result.id)
    end

    context 'when there are non-nil marks' do
      before do
        criterion = create(:rubric_criterion, assignment: assignment.pr_assignment)
        create(:mark, criterion: criterion, result: peer_review.result, mark: 2.5)
      end

      it 'aborts the callback' do
        expect { peer_review.check_marks_or_annotations }.to throw_symbol(:abort)
      end

      it 'prevents the deletion of the peer review' do
        expect { peer_review.destroy }.not_to(change { PeerReview.count })
      end
    end

    context 'when there are no marks or annotations' do
      it 'does not abort the callback' do
        expect { peer_review.check_marks_or_annotations }.not_to throw_symbol(:abort)
      end

      it 'allows the peer review to be deleted' do
        expect { peer_review.destroy }.to change { PeerReview.count }.by(-1)
      end
    end
  end
end
