describe TestRunsChannel do
  shared_examples 'can subscribe' do
    let(:assignment) do
      create(:assignment_for_student_tests, assignment_properties_attributes:
        { token_start_date: 1.hour.ago, enable_student_tests: true, remote_autotest_settings_id: 1,
          tokens_per_period: 1 })
    end
    before do
      subscribe course_id: role.course_id, assignment_id: assignment.id
    end

    it 'should establish a subscription' do
      expect(subscription).to be_confirmed
    end

    it 'should stream from the correct user instance' do
      expect(subscription).to have_stream_for(current_user)
    end
  end

  context 'when the role is a student' do
    let(:role) { create(:student) }
    let(:current_user) { role.user }

    before do
      stub_connection(current_user: current_user)
    end

    context 'when the student cannot run tests' do
      it 'should not establish a subscription' do
        subscribe course_id: role.course_id
        expect(subscription).to be_rejected
      end
    end

    context 'when the student can run tests' do
      it_behaves_like 'can subscribe'
    end
  end

  context 'when the role is a ta' do
    let(:role) { create(:ta, run_tests: true) }
    let(:current_user) { role.user }

    before do
      stub_connection(current_user: current_user)
    end

    context 'when the ta cannot run tests' do
      let(:role) { create(:ta, run_tests: false) }

      it 'should not establish a subscription' do
        subscribe course_id: role.course_id
        expect(subscription).to be_rejected
      end
    end

    context 'when the ta can run tests' do
      it_behaves_like 'can subscribe'
    end
  end

  context 'when the role is an instructor' do
    let(:role) { create(:instructor) }
    let(:current_user) { role.user }

    before do
      stub_connection(current_user: current_user)
    end

    context 'when the instructor cannot run tests' do
      let(:assignment) do
        create(:assignment, assignment_properties_attributes: { enable_test: false })
      end

      it 'should not establish a subscription' do
        subscribe course_id: role.course_id, assignment_id: assignment.id
        expect(subscription).to be_rejected
      end
    end

    context 'when the instructor can run tests' do
      it_behaves_like 'can subscribe'
    end
  end

  context 'when the user in conjunction with the course_id do not identify a role' do
    let(:role) { create(:instructor) }
    let(:current_user) { role.user }

    before do
      stub_connection(current_user: current_user)
    end

    context 'when course_id is nil' do
      it 'should not establish a subscription' do
        subscribe course_id: nil
        expect(subscription).to be_rejected
      end
    end

    context 'when course_id is not nil' do
      it 'should not establish a subscription' do
        subscribe course_id: -1
        expect(subscription).to be_rejected
      end
    end
  end
end
