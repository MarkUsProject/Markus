describe Note do
  subject { create :note }
  it { should validate_presence_of(:notes_message) }
  it { should belong_to(:noteable) }
  it { should belong_to(:role) }
  it { is_expected.to have_one(:course) }
  include_examples 'course associations'

  context 'noteables_exist?' do
    it 'return false when no noteables exist' do
      Assignment.destroy_all
      Grouping.destroy_all
      Student.destroy_all
      expect(Note.noteables_exist?).to be false
    end
  end

  { Grouping: -> { FactoryBot.create(:grouping) },
    Student: -> { FactoryBot.create(:student) },
    Assignment: -> { FactoryBot.create(:assignment) } }.each_pair do |type, noteable|
    context "when #{type} exist" do
      before do
        @noteable = noteable.call
      end
      it 'return true' do
        expect(Note.noteables_exist?).to be true
      end
    end
  end
end
