describe CollectSubmissionsChannel do
  context 'when a user can collect submissions' do
    let!(:instructor) { create(:instructor) }
    let!(:current_user) { instructor.user }

    context 'when a course is passed in on subscription' do
      before do
        stub_connection(current_user: current_user)
        subscribe course_id: instructor.course_id
      end

      it 'should succeed' do
        # Asserts that the subscription was successfully created
        expect(subscription).to be_confirmed
      end

      it 'should stream from the correct user instance' do
        # Asserts that the channel subscribes connection to a stream created with `stream_for`
        expect(subscription).to have_stream_for(current_user)
      end
    end

    context 'when a course is not passed in on subscription' do
      it 'should fail' do
        stub_connection(current_user: current_user)
        subscribe course_id: nil
        expect(subscription).to be_rejected
      end
    end

    context 'when the course passed in, in conjunction with the current_user, don\'t identify a role' do
      it 'should fail' do
        stub_connection(current_user: current_user)
        subscribe course_id: -1
        expect(subscription).to be_rejected
      end
    end
  end

  context 'when a user cannot collect submissions' do
    let!(:student) { create(:student) }
    let!(:current_user) { student.user }

    it 'should reject the subscription' do
      stub_connection(current_user: current_user)
      subscribe course_id: student.course_id
      expect(subscription).to be_rejected
    end
  end
end
