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
    let(:human) { create :human}
    let!(:student) { create :student, course: course, human: human }
    context 'when there is a visible course' do
      it 'returns the course' do
        expect(human.visible_courses).to contain_exactly(course)
      end
    end
    context 'when there is a hidden course' do
      let(:course) { create :course }
      it 'does not return the course' do
        expect(human.visible_courses).to be_empty
      end
    end
    context 'when a student is hidden in a course' do
      let(:human) { create :human }
      let!(:student) { create :student, course: course, hidden: true, human: human }
      it 'does not return the course' do
        expect(human.visible_courses).to be_empty
      end
    end
    context 'when there are multiple courses' do
      let(:human2) { create :human }
      let(:course2) { create :course }
      let!(:student2) { create :student, human: human2, course: course2 }
      let!(:student2c1) { create :student, human: human2, course: course }
      let(:course3) { create :course, is_hidden: false }
      let(:human3) { create :human }
      let!(:student3) { create :student, human: human3, course: course, hidden: true }
      let!(:student3c2) { create :student, human: human3, course: course2 }
      let!(:student3c3) { create :student, human: human3, course: course3 }
      let(:human4) { create :human }
      let!(:human4_student) { create :student, course: course, human: human4 }
      let!(:human4_ta) { create :ta, course: course2, human: human4 }
      let!(:human4_admin) { create :admin, human: human4, course: course3 }
      it 'returns only courses human1 can see' do
        expect(human.visible_courses).to contain_exactly(course)
      end
      it 'returns only visible courses for human 2' do
        expect(human2.visible_courses).to contain_exactly(course)
      end
      it 'returns only visible courses for human3' do
        expect(human3.visible_courses).to contain_exactly(course3)
      end
      it 'returns courses that are visible as a student, ta, or admin' do
        expect(human4.visible_courses).to contain_exactly(course, course2, course3)
      end
    end
  end
end
