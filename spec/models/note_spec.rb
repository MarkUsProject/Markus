require 'spec_helper'

describe Note do
  it { is_expected.to validate_presence_of(:notes_message) }
  it { is_expected.to validate_presence_of(:creator_id) }
  it { is_expected.to validate_presence_of(:noteable) }
  it { is_expected.to belong_to(:noteable) }
  it { is_expected.to belong_to(:user) }

  context 'noteables_exist?'  do
    it 'return false when no noteables exist' do
      Assignment.destroy_all
      Grouping.destroy_all
      Student.destroy_all
      expect(Note.noteables_exist?).to be false
    end
  end

  {Grouping: lambda {FactoryGirl.create(:grouping)},
   Student: lambda {FactoryGirl.create(:student)},
   Assignment: lambda {FactoryGirl.create(:assignment)}}.each_pair do |type, noteable|
    context "when #{type.to_s} exist" do
      before {
        @noteable = noteable.call()
      }
      it 'return true' do
        expect(Note.noteables_exist?).to be true
      end
    end
  end
end
