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

  shared_examples 'testing noteable on different models' do
    it 'returns true for the notable\'s course' do
      expect(Note.noteables_exist?(noteable.course.id)).to be true
    end
    it 'returns false for a different course' do
      course = create(:course)
      expect(Note.noteables_exist?(course.id)).to be false
    end
  end

  context 'when Grouping exist' do
    include_examples 'testing noteable on different models' do
      let(:noteable) { create(:grouping) }
    end
  end

  context 'when Grouping exist' do
    include_examples 'testing noteable on different models' do
      let(:noteable) { create(:student) }
    end
  end

  context 'when Grouping exist' do
    include_examples 'testing noteable on different models' do
      let(:noteable) { create(:assignment) }
    end
  end
end
