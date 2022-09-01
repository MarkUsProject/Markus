describe EndUser do
  context 'when role created' do
    let(:student) { create :student }
    it 'has roles' do
      expect(build(:end_user, roles: [student])).to be_valid
    end
  end
  describe '#visible_courses' do
    let(:course) { create :course }
    let(:end_user) { create :end_user }
    let!(:student) { create :student, course: course, user: end_user }
    context 'when there is a visible course' do
      it 'returns the course' do
        expect(end_user.visible_courses).to contain_exactly(course)
      end
    end
    context 'when there is a hidden course' do
      let(:course) { create :course, is_hidden: true }
      it 'does not return the course' do
        expect(end_user.visible_courses).to be_empty
      end

      context 'when the user is an instructor' do
        let(:end_user2) { create :end_user }
        let!(:instructor) { create :instructor, course: course, user: end_user2 }
        it 'returns the course' do
          expect(end_user2.visible_courses).to contain_exactly(course)
        end
      end

      context 'when the user is a grader' do
        let(:end_user2) { create :end_user }
        let!(:grader) { create :ta, course: course, user: end_user2 }
        it 'returns the course' do
          expect(end_user2.visible_courses).to contain_exactly(course)
        end
      end
    end
    context 'when a student is hidden in a course' do
      let(:end_user2) { create :end_user }
      let!(:student) { create :student, course: course, hidden: true, user: end_user2 }
      it 'does not return the course' do
        expect(end_user2.visible_courses).to be_empty
      end
    end
    context 'when there are multiple courses' do
      let(:end_user2) { create :end_user }
      let(:course2) { create :course, is_hidden: true }
      let!(:student2) { create :student, user: end_user2, course: course2 }
      let!(:student2c1) { create :student, user: end_user2, course: course }
      let(:course3) { create :course, is_hidden: false }
      let(:end_user3) { create :end_user }
      let!(:student3) { create :student, user: end_user3, course: course, hidden: true }
      let!(:student3c2) { create :student, user: end_user3, course: course2 }
      let!(:student3c3) { create :student, user: end_user3, course: course3 }
      let(:end_user4) { create :end_user }
      let!(:end_user4_student) { create :student, course: course, user: end_user4 }
      let!(:end_user4_ta) { create :ta, course: course2, user: end_user4 }
      let!(:end_user4_instructor) { create :instructor, user: end_user4, course: course3 }
      it 'returns only courses end_user1 can see' do
        expect(end_user.visible_courses).to contain_exactly(course)
      end
      it 'returns only visible courses for end_user2' do
        expect(end_user2.visible_courses).to contain_exactly(course)
      end
      it 'returns only visible courses for end_user3' do
        expect(end_user3.visible_courses).to contain_exactly(course3)
      end
      it 'returns courses that are visible as a student, ta, or instructor' do
        expect(end_user4.visible_courses).to contain_exactly(course, course2, course3)
      end
    end

    context 'when a grader is hidden in a course' do
      let(:end_user2) { create :end_user }
      let!(:grader) { create :ta, course: course, hidden: true, user: end_user2 }
      it 'does not return the course' do
        expect(end_user2.visible_courses).to be_empty
      end
    end

    context 'when an instructor is hidden in a course' do
      let(:end_user2) { create :end_user }
      let!(:instructor) { create :instructor, course: course, hidden: true, user: end_user2 }
      it 'does not return the course' do
        expect(end_user2.visible_courses).to be_empty
      end
    end
  end
end
