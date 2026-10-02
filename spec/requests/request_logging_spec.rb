describe 'Request logging' do
  let(:instructor) { create(:instructor) }
  let(:course) { instructor.course }

  # Returns the log entry written when the request made by the block was completed
  def completed_request_log_entry(&)
    capture_semantic_logger_events(&).find { |event| event.metric == 'rails.controller.process_action' }
  end

  it 'tags log entries with the request id and the IP address of the client' do
    entry = completed_request_log_entry { get '/', headers: { 'X-Request-Id' => 'test-request-id' } }
    expect(entry.named_tags).to eq(request_id: 'test-request-id', ip: '127.0.0.1')
  end

  it 'logs the status and filtered parameters of the request' do
    entry = completed_request_log_entry { post '/', params: { user_login: instructor.user_name, user_password: 'a' } }
    expect(entry).to be_a_semantic_logger_event(
      level: :info, name: 'MainController', message: 'Completed #login',
      payload_includes: { status: 302,
                          params: { 'user_login' => instructor.user_name, 'user_password' => '[FILTERED]' } }
    )
  end

  context 'when the user is logged in' do
    before { post '/', params: { user_login: instructor.user_name, user_password: 'a' } }

    it 'tags log entries with the user name of the user' do
      entry = completed_request_log_entry { get '/courses' }
      expect(entry.named_tags).to include(real_user_name: instructor.user_name, user_name: instructor.user_name)
    end

    it 'tags log entries with the user name of the user that an instructor switched roles to' do
      student = create(:student, course: course)
      get "/courses/#{course.id}"
      csrf_token = response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]
      post "/courses/#{course.id}/switch_role", params: { effective_user_login: student.user_name },
                                                headers: { 'X-CSRF-Token' => csrf_token }, xhr: true

      entry = completed_request_log_entry { get "/courses/#{course.id}/assignments" }
      expect(entry.named_tags).to include(real_user_name: instructor.user_name, user_name: student.user_name)
    end
  end

  context 'when the user is logged in with remote authentication' do
    before { get '/main/login_remote_auth' }

    it 'tags log entries with the user name of the remote user' do
      entry = completed_request_log_entry { get '/courses', headers: { 'X-Forwarded-User' => instructor.user_name } }
      expect(entry.named_tags).to include(real_user_name: instructor.user_name, user_name: instructor.user_name)
    end
  end
end
