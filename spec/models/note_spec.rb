describe Note do
  subject { create :note }
  it { should validate_presence_of(:notes_message) }
  it { should belong_to(:noteable) }
  it { should belong_to(:role) }
  it { is_expected.to have_one(:course) }
  include_examples 'course associations'

  context 'noteables_exist?' do
    it 'returns false when no noteables exist' do
      course = create(:course)
      Assignment.destroy_all
      Grouping.destroy_all
      Student.destroy_all
      expect(Note.noteables_exist?(course.id)).to be false
    end
  end

  { Grouping: -> { create(:grouping) },
    Student: -> { create(:student) },
    Assignment: -> { create(:assignment) } }.each_pair do |type, noteable|
    context "when #{type} exist" do
      before do
        @noteable = noteable.call
      end
      it 'returns true for the notable\'s course' do
        expect(Note.noteables_exist?(@noteable.course.id)).to be true
      end
      it 'returns false for a different course' do
        course = create(:course)
        expect(Note.noteables_exist?(course.id)).to be false
      end
    end
  end
end
