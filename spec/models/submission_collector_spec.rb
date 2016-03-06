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
    it 'should uncollect the submissions after a single collection' do
      @sub_collector.uncollect_submissions(@assignment)
      @assignment.submissions.each do |sub|
        expect(sub.grouping.is_collected).to eq false
        expect(sub.submission_version_used).to eq false
      end
    end
    it 'should uncollect the submissions after multiple collections' do
      @sub_collector.uncollect_submissions(@assignment)
      @assignment.reload
      @sub_collector.push_groupings_to_queue(@assignment.groupings)
      @sub_collector.uncollect_submissions(@assignment)
      submissions = @assignment.submissions
      versions = submissions.pluck(:submission_version).uniq
      last_version = versions[-1]
      prev_version = versions[-2]
      submissions.where(submission_version: last_version).each do |sub|
        expect(sub.submission_version_used).to eq false
      end
      submissions.where(submission_version: prev_version).each do |sub|
        expect(sub.grouping.is_collected).to eq true
        expect(sub.submission_version_used).to eq false
      end
    end
  end
end
