require 'spec_helper'

describe SubmissionCollector do

  context 'uncollect_submissions' do
    before(:each) do
      @assignment = FactoryGirl.create(:assignment)
      10.times { @assignment.groupings << FactoryGirl.create(:grouping)  }
      @sub_collector = SubmissionCollector.instance
      @sub_collector.push_groupings_to_queue(@assignment.groupings)
    end
    it 'should uncollect the submissions' do
      @sub_collector.uncollect_submissions(@assignment)
      debugger
      @assignment.submissions.each do |sub|
        expect(sub.grouping.is_collected).to eq false
        expect(sub.submission_version_used).to eq false
      end
    end
  end
end