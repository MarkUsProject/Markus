describe GroupsChannel do
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }

  context 'when a user can manage the assignment' do
    let(:role) { create(:instructor, course: course) }
    let(:user) { role.user }

    before do
      stub_connection(current_user: user, real_user: user)
      subscribe(course_id: course.id, assignment_id: assignment.id)
    end

    it 'subscribes to the channel' do
      expect(subscription).to be_confirmed
    end

    it 'streams for the current user' do
      expect(subscription).to have_stream_for(user)
    end
  end

  context 'when a user cannot manage the assignment' do
    let(:role) { create(:student, course: course) }
    let(:user) { role.user }

    before do
      stub_connection(current_user: user, real_user: user)
      subscribe(course_id: course.id, assignment_id: assignment.id)
    end

    it 'does not subscribe to the channel' do
      expect(subscription).to be_rejected
    end
  end

  context 'when a user cannot manage the course for this assignment' do
    let(:other_course) { create(:course) }
    let(:role) { create(:ta, manage_assessments: true, course: other_course) }
    let(:user) { role.user }

    before do
      stub_connection(current_user: user, real_user: user)
      subscribe(course_id: course.id, assignment_id: assignment.id)
    end

    it 'does not subscribe to the channel' do
      expect(subscription).to be_rejected
    end
  end

  context 'when a ta can manage assessments in the course' do
    let(:role) { create(:ta, manage_assessments: true, course: course) }
    let(:user) { role.user }

    before do
      stub_connection(current_user: user, real_user: user)
      subscribe(course_id: course.id, assignment_id: assignment.id)
    end

    it 'subscribes to the channel' do
      expect(subscription).to be_confirmed
    end

    it 'streams for the current user' do
      expect(subscription).to have_stream_for(user)
    end
  end
end
