describe Human do
  it { is_expected.to have_many(:roles) }
  context 'when role created' do
    let(:student) { create :student }
    it 'has roles' do
      expect(build(:human, roles: [student])).to be_valid
    end
  end
  describe '#visible_courses' do
    let(:course) { create :course, is_hidden: false }
    let(:student) { create :student, course: course }
    context 'when there is a visible course' do
      it 'returns the course' do
        expect(student.visible_courses).to contain_exactly(course)
      end
    end
    context 'when there is a hidden course' do
      let(:course) { create :course}
      it 'does not return the course' do
        expect(student.visible_courses).to be_empty
      end
    end
    context 'when a student is hidden in a course' do
      let(:student) { create :student, course: course, hidden: true }
      it 'does not return the course' do
        expect(student.visible_courses).to be_empty
      end
    end
    context 'when there are multiple courses' do
      let(:human2) { create :human }
      let(:course2) { create :course}
      let!(:student2) { create :student, human: human2, course: course2 }
      let!(:student2c1) { create :student, human: human2, course: course}
      let(:course3) { create :course, is_hidden: false }
      let(:human3) { create :human }
      let!(:student3) { create :student, human: human3, course: course, hidden: true }
      let!(:student3c2) { create :student, human: human3, course: course2 }
      let!(:student3c3) { create :student, human: human3, course: course3 }
      it 'returns only courses student1 can see' do
        expect(student.visible_courses).to contain_exactly(course)
      end
      it 'returns only visible courses for student 2' do
        expect(human2.visible_courses).to contain_exactly(course)
      end
      it 'returns no courses for student3' do
        expect(human3.visible_courses).to contain_exactly(course3)
      end
    end
  end
end
