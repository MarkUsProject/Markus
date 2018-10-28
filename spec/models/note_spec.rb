describe Note do
  it { should validate_presence_of(:notes_message) }
  it { should belong_to(:noteable) }
  it { should belong_to(:user) }

  context 'noteables_exist?'  do
    it 'return false when no noteables exist' do
      Assignment.destroy_all
      Grouping.destroy_all
      Student.destroy_all
      expect(Note.noteables_exist?).to be false
    end
  end

  {Grouping: lambda {FactoryBot.create(:grouping)},
   Student: lambda {FactoryBot.create(:student)},
   Assignment: lambda {FactoryBot.create(:assignment)}}.each_pair do |type, noteable|
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
