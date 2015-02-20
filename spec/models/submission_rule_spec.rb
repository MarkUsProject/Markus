require 'spec_helper'

describe SubmissionRule do
  it { is_expected.to belong_to(:assignment) }
  context '#calculate_collection_time' do
    let(:assignment) { create(:assignment) }


    it 'returns something other than nil at the end' do
      expect(assignment.submission_rule.calculate_collection_time).
            to_not be_nil
    end
    
    it 'returns date value at the end' do
      expect(assignment.submission_rule.
             calculate_collection_time.to_date).
             to be_kind_of(Date)
    end
  end
  
  
  context '#calculate_grouping_collection_time' do
      let(:assignment) { create(:assignment) }
      let(:grouping) { create(:grouping) }
      let(:grouping2) { create(:grouping2) }
      
      it 'returns something other than nil at the end' do
        expect(assignment.submission_rule.
               calculate_grouping_collection_time(grouping)).
               to_not be_nil
      end
      
      it 'returns date value at the end' do
        expect(assignment.submission_rule.
               calculate_grouping_collection_time(grouping).to_date).
               to be_kind_of(Date)
      end

      # test that is triggered when grouping.inviter.section exists
      it 'returns date value if grouping.inviter.section is not nil' do
        expect(assignment.submission_rule.
        calculate_grouping_collection_time(grouping2).to_date).
        to be_kind_of(Date)
      end
  end

end
