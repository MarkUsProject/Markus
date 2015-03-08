require 'spec_helper'

describe SubmissionRule do
  it { is_expected.to belong_to(:assignment) }
  context '#calculate_collection_time' do
    let(:assignment) { create(:assignment) }

    it 'returns something other than nil at the end' do
      expect(assignment.submission_rule.calculate_collection_time)
        .to_not be_nil
    end

    it 'returns some date value at the end' do
      expect(assignment.submission_rule
        .calculate_collection_time.to_date)
        .to be_kind_of(Date)
    end

    # in accuracy range of 10 minutes
    it 'returns a correct time value at the end' do
      time_returned = assignment.submission_rule.calculate_collection_time
      time_now = Time.now
      time_difference = (time_now - time_returned).abs
      expect(time_difference)
        .to be < 600
    end

  end

  context '#calculate_grouping_collection_time' do
    let(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping) }
    let(:grouping_with_inviter) { create(:grouping_with_inviter) }

    it 'returns something other than nil at the end' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping))
        .to_not be_nil
    end

    it 'returns some date value at the end' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping).to_date)
        .to be_kind_of(Date)
    end
    
    # in accuracy range of 10 minutes
    it 'returns a correct time value at the end' do
      time_returned = assignment.submission_rule
                      .calculate_grouping_collection_time(grouping)
      time_now = Time.now
      time_difference = (time_now - time_returned).abs
      expect(time_difference)
        .to be < 600
    end

    # test that is triggered when grouping.inviter.section exists
    it 'returns date value if grouping.inviter.section is not nil' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping_with_inviter).to_date)
        .to be_kind_of(Date)
    end
  end

end
