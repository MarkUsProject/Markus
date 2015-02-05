require 'spec_helper'

describe SubmissionRule do
  it { is_expected.to belong_to(:assignment) }
  
  context '#calculate_collection_time' do
      let(:assignment) { create(:assignment) }

      
    it 'returns something other than nil' do
      expect(assignment.submission_rule.calculate_collection_time).to_not be_nil
    end
    
    it 'returns date value' do
      expect(assignment.submission_rule.calculate_collection_time.to_date).to be_kind_of(Date)
    end
  end
  
  
  context '#calculate_grouping_collection_time' do
      let(:assignment) { create(:assignment) }
      let(:grouping) { create(:grouping) }
      
      it 'returns something other than nil' do
          expect(assignment.submission_rule.calculate_grouping_collection_time(grouping)).to_not be_nil
      end
      
      it 'returns date value' do
          expect(assignment.submission_rule.calculate_grouping_collection_time(grouping).to_date).to be_kind_of(Date)
      end
      
      #create a new test that is triggered when grouping exists
  end
  
end
