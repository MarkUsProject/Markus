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
      @submission = create(:submission)
      @result = create(:result, submission: @submission)
      @submission.update(remark_request_timestamp: Time.zone.now)
      @submission.make_remark_result
      @submission.remark_result.update(remark_request_submitted_at: nil)
    end

    describe 'handle remarks with updates' do
      it 'should return true on has_remark? call' do
        expect(@submission.has_remark?).to be true
      end
    end

    # TODO
    # it 'should return false on remark_submitted? call' do
    #   expect(@submission.remark_submitted?).to be false
    # end
  end

  # context 'A submission with no remark results' do
  #   setup do
  #     @submission = Submission.make
  #     @submission.save
  #   end
  #   should 'return false on has_remark? call' do
  #     assert !@submission.has_remark?
  #   end
  #   should 'return false on remark_submitted? call' do
  #     assert !@submission.remark_submitted?
  #   end
  # end
  #
  # context 'The Submission class' do
  #   should 'be able to find a submission object by group name and assignment short identifier' do
  #     # existing submission
  #     assignment = Assignment.make
  #     group = Group.make
  #     grouping = Grouping.make(:assignment => assignment,
  #                              :group => group)
  #     submission = Submission.make(:grouping => grouping)
  #
  #     sub2 = Submission.get_submission_by_group_and_assignment(group.group_name,
  #                                                              assignment.short_identifier)
  #     assert_not_nil(sub2)
  #     assert_instance_of(Submission, sub2)
  #     assert_equal(submission, sub2)
  #     # non existing test results
  #     assert_nil(
  #         Submission.get_submission_by_group_and_assignment(
  #             'group_name_not_there',
  #             'A_not_there'))
  #   end
  # end
  #
  # should 'create a remark result' do
  #   s = Submission.make
  #   s.update(remark_request_timestamp: Time.zone.now)
  #   s.make_remark_result
  #   assert_not_nil s.remark_result, 'Remark result was supposed to be created'
  #   assert_equal s.remark_result.marking_state,
  #                Result::MARKING_STATES[:incomplete],
  #                'Remark result marking_state should have been ' +
  #                    'automatically set to incomplete'
  # end
end
