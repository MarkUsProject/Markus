describe Jupyter::JupyterSubmissionsController do
  let(:course) { create(:course) }
  let(:origin) { 'http://jupyter.example.test' }
  let(:base_url) { "#{origin}/user/testuser/" }
  let(:token) { 'test-token-123' }
  let(:notebook_path) { 'homework/hw1.ipynb' }
  let(:notebook_content) { { 'cells' => [], 'metadata' => {}, 'nbformat' => 4, 'nbformat_minor' => 5 } }

  let(:jupyter_params) { { base_url: base_url, token: token } }
  let(:valid_params) do
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

  before do
    allow(Settings.jupyter).to receive(:enabled).and_return(true)
    allow(Settings.jupyter_server).to receive(:hosts).and_return([origin])
  end

  describe 'successful submissions' do
    context 'when the assignment only allows students to work alone' do
      let(:assignment) { create(:assignment, course: course, assignment_properties_attributes: { api_submit: true }) }
      let!(:student) { create(:student, course: course) }

      before do
        stub_hub_identity(user_name: student.user_name)
        stub_notebook_contents
      end

      it 'creates a solo group for the student and submits the notebook to the repo' do
        post :submit, params: valid_params

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
    end

    context 'when the assignment allows groups of students' do
      let(:assignment) do
        create(:assignment, course: course, assignment_properties_attributes: { group_max: 3, api_submit: true })
      end
      let!(:student) { create(:student, course: course) }

      before do
        stub_hub_identity(user_name: student.user_name)
        stub_notebook_contents
      end

      it 'auto-creates a group for the student and submits the notebook' do
        expect(student.has_accepted_grouping_for?(assignment.id)).to be false

        post :submit, params: valid_params

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

      post :submit, params: valid_params

      expect(response).to have_http_status :service_unavailable
    end

    it 'returns 400 when a top-level required param is missing' do
      post :submit, params: valid_params.except(:notebook_path)

      expect(response).to have_http_status :bad_request
    end

    it 'returns 400 when a required jupyter field is missing' do
      post :submit, params: valid_params.merge(jupyter: jupyter_params.except(:token))

      expect(response).to have_http_status :bad_request
    end

    it 'returns 400 when base_url is not an absolute http(s) URL' do
      post :submit, params: valid_params.merge(jupyter: jupyter_params.merge(base_url: 'not-a-url'))

      expect(response).to have_http_status :bad_request
    end

    it 'returns 400 when the base_url origin is not in the configured allowlist' do
      allow(Settings.jupyter_server).to receive(:hosts).and_return(['http://a-different-host.test'])

      post :submit, params: valid_params

      expect(response).to have_http_status :bad_request
    end

    it 'returns 401 when the JupyterHub identity lookup fails' do
      stub_hub_identity(user_name: student.user_name, status: 403)

      post :submit, params: valid_params

      expect(response).to have_http_status :unauthorized
    end

    it 'returns 404 when the JupyterHub user has no matching MarkUs account' do
      stub_hub_identity(user_name: 'no-such-markus-user')

      post :submit, params: valid_params

      expect(response).to have_http_status :not_found
    end

    it 'returns 404 when the course cannot be found' do
      stub_hub_identity(user_name: student.user_name)

      post :submit, params: valid_params.merge(course_id: -1)

      expect(response).to have_http_status :not_found
    end

    it 'returns 403 when the user is not a student in the given course' do
      outsider = create(:student, course: create(:course))
      stub_hub_identity(user_name: outsider.user_name)

      post :submit, params: valid_params

      expect(response).to have_http_status :forbidden
    end

    it 'returns 404 when the assignment cannot be found' do
      stub_hub_identity(user_name: student.user_name)

      post :submit, params: valid_params.merge(assignment_id: -1)

      expect(response).to have_http_status :not_found
    end

    it 'returns 403 when API submission is disabled for the assignment' do
      stub_hub_identity(user_name: student.user_name)

      post :submit, params: valid_params

      expect(response).to have_http_status :forbidden
      expect(response.parsed_body['message']).to eq I18n.t('submissions.api_submission_disabled')
    end

    it 'returns 502 when fetching the notebook contents fails' do
      enabled_assignment = create(:assignment, course: course, assignment_properties_attributes: { api_submit: true })
      stub_hub_identity(user_name: student.user_name)
      stub_notebook_contents(status: 404, body: 'Not Found')

      post :submit, params: valid_params.merge(assignment_id: enabled_assignment.id)

      expect(response).to have_http_status :bad_gateway
    end

    it 'returns 422 when the repository rejects the submission' do
      required_assignment = create(:assignment, course: course,
                                                assignment_properties_attributes: { only_required_files: true,
                                                                                    api_submit: true })
      create(:assignment_file, assignment: required_assignment, filename: 'required.ipynb')
      stub_hub_identity(user_name: student.user_name)
      stub_notebook_contents

      post :submit, params: valid_params.merge(assignment_id: required_assignment.id)

      expect(response).to have_http_status :unprocessable_content
    end
  end
end
