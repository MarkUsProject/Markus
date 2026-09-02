describe Jupyter::JupyterSubmissionsController do
  let(:course) { create(:course) }
  let(:origin) { 'http://jupyter.example.test' }
  let(:base_url) { "#{origin}/user/testuser/" }
  let(:token) { 'test-token-123' }
  let(:notebook_path) { 'homework/hw1.ipynb' }
  let(:notebook_content) { { 'cells' => [], 'metadata' => {}, 'nbformat' => 4, 'nbformat_minor' => 5 } }

  let(:jupyter_params) { { base_url: base_url, token: token } }
  let(:base_submit_params) do
    {
      notebook_path: notebook_path,
      course_id: course.id,
      assignment_id: assignment.id,
      jupyter: jupyter_params
    }
  end

  def stub_hub_identity(user_name:, status: 200)
    stub_request(:get, "#{origin}/hub/api/user")
      .with(headers: { 'Authorization' => "token #{token}", 'Accept' => 'application/json' })
      .to_return(status: status, body: { name: user_name }.to_json)
  end

  def stub_notebook_contents(status: 200, body: nil)
    body ||= {
      name: File.basename(notebook_path),
      path: notebook_path,
      type: 'notebook',
      format: 'json',
      mimetype: nil,
      writable: true,
      content: notebook_content
    }.to_json

    stub_request(:get, "#{base_url}api/contents/#{notebook_path}")
      .with(query: { content: '1' }, headers: { 'Authorization' => "token #{token}" })
      .to_return(status: status, body: body)
  end

  # Authenticates via jupyter/authenticate (stubbing the Hub identity lookup) and returns the
  # resulting session_token, so submit specs don't need to re-derive one by hand.
  def create_session_token!(user_name:)
    stub_hub_identity(user_name: user_name)
    post :create_session, params: { jupyter: jupyter_params }
    response.parsed_body.fetch('session_token')
  end

  before do
    allow(Settings.jupyter).to receive(:enabled).and_return(true)
    allow(Settings.jupyter_server).to receive(:hosts).and_return([origin])
  end

  describe 'authenticate' do
    let!(:student) { create(:student, course: course) }

    it 'returns a session_token and the markus_user_name for a valid Hub token' do
      stub_hub_identity(user_name: student.user_name)

      post :create_session, params: { jupyter: jupyter_params }

      expect(response).to have_http_status :ok
      body = response.parsed_body
      expect(body['status']).to eq 'success'
      expect(body['session_token']).to be_present
      expect(body['markus_user_name']).to eq student.user_name
    end

    it 'returns 401 when the JupyterHub identity lookup fails' do
      stub_hub_identity(user_name: student.user_name, status: 403)

      post :create_session, params: { jupyter: jupyter_params }

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 404 when the JupyterHub user has no matching MarkUs account' do
      stub_hub_identity(user_name: 'no-such-markus-user')

      post :create_session, params: { jupyter: jupyter_params }

      expect(response).to have_http_status :not_found
    end

    it 'returns 503 when the jupyter feature flag is disabled' do
      allow(Settings.jupyter).to receive(:enabled).and_return(false)

      post :create_session, params: { jupyter: jupyter_params }

      expect(response).to have_http_status :service_unavailable
    end
  end

  describe 'successful submissions' do
    context 'when the assignment only allows students to work alone' do
      let(:assignment) { create(:assignment, course: course, assignment_properties_attributes: { api_submit: true }) }
      let!(:student) { create(:student, course: course) }

      before { stub_notebook_contents }

      it 'creates a solo group for the student and submits the notebook to the repo' do
        session_token = create_session_token!(user_name: student.user_name)

        post :submit, params: base_submit_params.merge(session_token: session_token)

        expect(response).to have_http_status :ok
        body = response.parsed_body
        expect(body['status']).to eq 'success'
        expect(body['submitted_file']).to eq 'hw1.ipynb'
        expect(body['markus_target']).to eq(
          'course_id' => course.id,
          'course' => course.name,
          'assignment_id' => assignment.id,
          'assignment' => assignment.short_identifier,
          'markus_user_name' => student.user_name
        )

        grouping = student.accepted_grouping_for(assignment.id)
        expect(grouping).not_to be_nil
        grouping.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(assignment.repository_folder)
          expect(files['hw1.ipynb']).not_to be_nil
        end
      end

      it 'does not write to the MarkUs session cookie' do
        session_token = create_session_token!(user_name: student.user_name)

        post :submit, params: base_submit_params.merge(session_token: session_token)

        expect(session[:user_name]).to be_nil
      end

      it 'does not re-verify identity against JupyterHub when submitting' do
        session_token = create_session_token!(user_name: student.user_name)

        post :submit, params: base_submit_params.merge(session_token: session_token)

        expect(response).to have_http_status :ok
        expect(WebMock).to have_requested(:get, "#{origin}/hub/api/user").once
      end
    end

    context 'when the assignment allows groups of students' do
      let(:assignment) do
        create(:assignment, course: course, assignment_properties_attributes: { group_max: 3, api_submit: true })
      end
      let!(:student) { create(:student, course: course) }

      before { stub_notebook_contents }

      it 'auto-creates a group for the student and submits the notebook' do
        expect(student.has_accepted_grouping_for?(assignment.id)).to be false

        session_token = create_session_token!(user_name: student.user_name)
        post :submit, params: base_submit_params.merge(session_token: session_token)

        expect(response).to have_http_status :ok
        expect(student.has_accepted_grouping_for?(assignment.id)).to be true
      end
    end
  end

  describe 'error handling' do
    let(:assignment) { create(:assignment, course: course) }
    let!(:student) { create(:student, course: course) }

    it 'returns 503 when the jupyter feature flag is disabled' do
      allow(Settings.jupyter).to receive(:enabled).and_return(false)

      post :submit, params: base_submit_params

      expect(response).to have_http_status :service_unavailable
    end

    it 'returns 401 when session_token is missing' do
      post :submit, params: base_submit_params

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 400 when a required jupyter field is missing' do
      post :submit, params: base_submit_params.merge(jupyter: jupyter_params.except(:token), session_token: 'x')

      expect(response).to have_http_status :bad_request
    end

    it 'returns 400 when base_url is not an absolute http(s) URL' do
      post :submit, params: base_submit_params.merge(jupyter: jupyter_params.merge(base_url: 'not-a-url'),
                                                     session_token: 'x')

      expect(response).to have_http_status :bad_request
    end

    it 'returns 400 when the base_url origin is not in the configured allowlist' do
      session_token = create_session_token!(user_name: student.user_name)
      allow(Settings.jupyter_server).to receive(:hosts).and_return(['http://a-different-host.test'])

      post :submit, params: base_submit_params.merge(session_token: session_token)

      expect(response).to have_http_status :bad_request
    end

    it 'returns 401 when session_token is garbage/tampered' do
      post :submit, params: base_submit_params.merge(session_token: 'not-a-real-session-token')

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 401 when session_token has expired' do
      payload = {
        'user_name' => student.user_name,
        'origin' => origin,
        'token_hash' => Digest::SHA256.hexdigest(token),
        'expires_at' => 1.minute.ago.to_i
      }
      expired_token = Rails.application.message_verifier(:jupyter_session).generate(payload)

      post :submit, params: base_submit_params.merge(session_token: expired_token)

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 401 when session_token was issued for a different Jupyter token (spoofing attempt)' do
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.merge(
        jupyter: jupyter_params.merge(token: 'a-different-token'),
        session_token: session_token
      )

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 401 when session_token was issued for a different Jupyter origin' do
      second_origin = 'http://other-jupyter.example.test'
      allow(Settings.jupyter_server).to receive(:hosts).and_return([origin, second_origin])
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.merge(
        jupyter: jupyter_params.merge(base_url: "#{second_origin}/user/testuser/"),
        session_token: session_token
      )

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 400 when a top-level required param is missing' do
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.except(:notebook_path).merge(session_token: session_token)

      expect(response).to have_http_status :bad_request
    end

    it 'returns 404 when the course cannot be found' do
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.merge(course_id: -1, session_token: session_token)

      expect(response).to have_http_status :not_found
    end

    it 'returns 403 when the user is not a student in the given course' do
      outsider = create(:student, course: create(:course))
      session_token = create_session_token!(user_name: outsider.user_name)

      post :submit, params: base_submit_params.merge(session_token: session_token)

      expect(response).to have_http_status :forbidden
    end

    it 'returns 404 when the assignment cannot be found' do
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.merge(assignment_id: -1, session_token: session_token)

      expect(response).to have_http_status :not_found
    end

    it 'returns 403 when API submission is disabled for the assignment' do
      session_token = create_session_token!(user_name: student.user_name)

      post :submit, params: base_submit_params.merge(session_token: session_token)

      expect(response).to have_http_status :forbidden
      expect(response.parsed_body['message']).to eq I18n.t('submissions.api_submission_disabled')
    end

    it 'returns 502 when fetching the notebook contents fails' do
      enabled_assignment = create(:assignment, course: course, assignment_properties_attributes: { api_submit: true })
      session_token = create_session_token!(user_name: student.user_name)
      stub_notebook_contents(status: 404, body: 'Not Found')

      post :submit, params: base_submit_params.merge(assignment_id: enabled_assignment.id,
                                                     session_token: session_token)

      expect(response).to have_http_status :bad_gateway
    end

    it 'returns 422 when the repository rejects the submission' do
      required_assignment = create(:assignment, course: course,
                                                assignment_properties_attributes: { only_required_files: true,
                                                                                    api_submit: true })
      create(:assignment_file, assignment: required_assignment, filename: 'required.ipynb')
      session_token = create_session_token!(user_name: student.user_name)
      stub_notebook_contents

      post :submit, params: base_submit_params.merge(assignment_id: required_assignment.id,
                                                     session_token: session_token)

      expect(response).to have_http_status :unprocessable_content
    end
  end
end
