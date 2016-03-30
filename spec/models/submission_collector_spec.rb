require 'spec_helper'

describe SubmissionCollector do
  context 'uncollect_submissions' do
    before(:each) do
      @assignment = FactoryGirl.create(:assignment)
      10.times do
        @assignment.groupings << FactoryGirl.create(:grouping_with_inviter)
      end
      @sub_collector = SubmissionCollector.instance
      @sub_collector.push_groupings_to_queue(@assignment.groupings)
    end
    it 'should uncollect the submissions after collection' do
      @sub_collector.uncollect_submissions(@assignment)
      expect(@assignment.submissions.size).to eq(0)
    end
  end
end
