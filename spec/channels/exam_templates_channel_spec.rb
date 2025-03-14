describe ExamTemplatesChannel do
  context 'when a user can update submissions' do
    let!(:course) { create(:course) }
    let!(:role) { create(:instructor) }
    let!(:user) { role.user }

    before do
      stub_connection(current_user: user)
      subscribe(course_id: course.id)
    end

    it 'should subscribe to the channel' do
      expect(subscription).to be_confirmed
    end

    it 'should stream for the current user' do
      expect(subscription).to have_stream_for(user)
    end

    it 'broadcasts messages from the correct channel' do
      expect do
        ActionCable.server.broadcast 'messages', { message: 'Hello World' }
      end.to have_broadcasted_to('messages').from_channel(ExamTemplatesChannel)
    end
  end

  context 'when a user cannot update submissions' do
    let!(:course) { create(:course) }
    let!(:role) { create(:student) }
    let!(:user) { role.user }

    before do
      stub_connection(current_user: user)
      subscribe(course_id: course.id)
    end

    it 'should not subscribe to the channel' do
      expect(subscription).to be_rejected
    end
  end

  context 'when a user cannot update all submissions' do
    let!(:course) { create(:course) }
    let!(:course2) { create(:course) }
    let!(:role) { create(:ta, manage_submissions: true, course: course2) }
    let!(:user) { role.user }

    it 'should not subscribe to the channel for the course it cannot access' do
      stub_connection(current_user: user)
      subscribe(course_id: course.id)
      expect(subscription).to be_rejected
    end

    it 'should subscribe to and have a stream for the channel for the course it can access' do
      stub_connection(current_user: user)
      subscribe(course_id: course2.id)
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(user)
    end
  end
end
