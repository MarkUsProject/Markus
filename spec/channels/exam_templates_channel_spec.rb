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
end
