require 'spec_helper'

describe Submission do
  describe 'validations' do
    it { is_expected.to have_many(:submission_files) }
    it { is_expected.to have_many(:test_script_results) }
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
    it 'should have proper remarking status' do
      @submission = create(:submission)
      @submission.update(remark_request_timestamp: Time.zone.now)
      @submission.make_remark_result
      expect(@submission.has_remark?).to be true
      expect(@submission.remark_submitted?).to be true
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
    it 'should be able to find a submission object by group name and assignment short identifier' do
      assignment = create(:assignment)
      group = create(:group)
      grouping = create(:grouping, assignment: assignment, group: group)
      submission = create(:version_used_submission, grouping: grouping)
      sub2 = Submission.get_submission_by_group_and_assignment(group.group_name,
                                                               assignment.short_identifier)
      expect(sub2).to_not be_nil
      expect(sub2).to be_a Submission
      expect(sub2).to eq submission
      expect(Submission.get_submission_by_group_and_assignment(
              'group_name_not_there',
              'A_not_there')).to be_nil
    end

    it 'create a remark result' do
      s = create(:submission)
      s.update(remark_request_timestamp: Time.zone.now)
      s.make_remark_result
      expect(s.remark_result).to_not be_nil
      expect(s.remark_result.marking_state).to eq Result::MARKING_STATES[:incomplete]
    end
  end
end
