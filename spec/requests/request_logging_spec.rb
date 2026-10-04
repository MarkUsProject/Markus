describe 'Request logging' do
  let(:instructor) { create(:instructor) }

  # Returns the log entry written when the request made by the block was completed
  def completed_request_log_entry(&)
    capture_semantic_logger_events(&).find { |event| event.metric == 'rails.controller.process_action' }
  end

  it 'tags log entries with the IP address of the client' do
    entry = completed_request_log_entry { get '/' }
    expect(entry.named_tags).to eq(ip: '127.0.0.1')
  end

  it 'tags log entries with the user name of the user who is logged in' do
    post '/', params: { user_login: instructor.user_name, user_password: 'a' }
    entry = completed_request_log_entry { get '/courses' }
    expect(entry.named_tags).to eq(ip: '127.0.0.1', user_name: instructor.user_name)
  end
end
