describe Submission do
  describe 'validations' do
    it { is_expected.to have_many(:submission_files) }
    it { is_expected.to have_many(:test_runs) }
  end

  context 'automatically create a result' do
    it 'should create result automatically' do
      submission = create(:submission)
      expect(submission).to_not be_nil
    end

    it 'should have marking automatically set to be incomplete' do
      submission = create(:submission)
      expect(submission.get_latest_result.marking_state).to eq(Result::MARKING_STATES[:incomplete])
    end

    it 'should create a new remark result' do
      submission = create(:submission)
      submission.update(remark_request_timestamp: Time.zone.now)
      submission.make_remark_result
      expect(submission.remark_result).to_not be_nil
      expect(submission.remark_result.marking_state).to eq(Result::MARKING_STATES[:incomplete])
    end
  end

  context 'handle remark requests' do
    let(:submission) do
      submission = create(:submission)
      submission.update(remark_request_timestamp: Time.zone.now)
      submission
    end
    let(:extra_mark) { create(:extra_mark, result: submission.results.first) }

    it 'should have proper remarking status' do
      submission.make_remark_result
      expect(submission.has_remark?).to be true
      expect(submission.remark_submitted?).to be true
    end

    it 'should create another extra mark if there was one originally' do
      extra_mark
      submission.make_remark_result
      marks = ExtraMark.where(result_id: [submission.get_original_result.id, submission.remark_result.id])
      expect(marks.count).to eq(2)
    end

    it 'should copy extra marks from the original result to the remark request' do
      extra_mark
      submission.make_remark_result
      marks = ExtraMark.where(result_id: [submission.get_original_result.id, submission.remark_result.id])
      attributes = marks.pluck('description', 'extra_mark', 'unit')
      expect(attributes[0]).to eq(attributes[1])
    end
  end

  describe 'submission with a remark result created but not submitted' do
    before :each do
      @result = create(:result, marking_state: Result::MARKING_STATES[:incomplete])
      @submission = @result.submission
      @submission.update(remark_request_timestamp: Time.zone.now)
      @submission.make_remark_result
      @submission.remark_result.update(remark_request_submitted_at: nil)
    end

    describe 'handle remarks with updates' do
      it 'should return true on has_remark? call' do
        expect(@submission.has_remark?).to be true
      end
    end

    it 'should return false on remark_submitted? call' do
      expect(@submission.remark_submitted?).to be false
    end
  end

  describe 'A submission with no remark results' do
    before :each do
      @submission = create(:submission)
      @submission.save
    end

    it 'return false on has_remark? call' do
      expect(@submission.has_remark?).to be false
    end

    it 'return false on remark_submitted? call' do
      expect(@submission.remark_submitted?).to be false
    end
  end

  describe 'The Submission class' do
    it 'create a remark result' do
      s = create(:submission)
      s.update(remark_request_timestamp: Time.zone.now)
      s.make_remark_result
      expect(s.remark_result).to_not be_nil
      expect(s.remark_result.marking_state).to eq Result::MARKING_STATES[:incomplete]
    end
  end
end
