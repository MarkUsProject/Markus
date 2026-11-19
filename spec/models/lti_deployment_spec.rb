describe LtiDeployment do
  context 'relationships' do
    it { is_expected.to belong_to(:course).optional }
  end

  describe '#send_lti_request!' do
    subject do
      uri = URI(url)
      lti_deployment.send_lti_request!(Net::HTTP::Get.new(uri), uri, auth_data, [LtiDeployment::LTI_SCOPES[:names_role]])
    end

    let(:client_host) { 'https://test.host' }
    let(:lti_deployment) { create(:lti_deployment, lti_client: create(:lti_client, host: client_host)) }
    let(:auth_data) { { 'token_type' => 'Bearer', 'access_token' => 'access_token' } }

    shared_examples 'an LMS url' do
      it 'sends the request with the access token' do
        stub = stub_request(:get, url).with(headers: { 'Authorization' => 'Bearer access_token' }).to_return(body: '{}')
        subject
        expect(stub).to have_been_requested
      end
    end

    shared_examples 'a url outside the LMS' do
      it 'raises an error that names the host' do
        expect { subject }.to raise_error(LtiDeployment::UntrustedHostException,
                                          I18n.t('lti.untrusted_lms_host', host: URI(url).host))
      end

      it 'sends no request' do
        expect { subject }.to raise_error(LtiDeployment::UntrustedHostException)
        expect(a_request(:get, url)).not_to have_been_made
      end
    end

    context 'when the url is on the LMS host' do
      let(:url) { 'https://test.host/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'an LMS url'
    end

    context 'when the url host is in upper case' do
      let(:url) { 'https://TEST.HOST/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'an LMS url'
    end

    context 'when the LMS host has an explicit default port' do
      let(:client_host) { 'https://test.host:443' }
      let(:url) { 'https://test.host/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'an LMS url'
    end

    context 'when the url is on another LMS domain from the settings' do
      let(:url) { 'https://canvas.example.edu/api/lti/courses/1/names_and_roles' }

      before { allow(Settings.lti).to receive(:domains).and_return(%w[test.host canvas.example.edu]) }

      it_behaves_like 'an LMS url'
    end

    context 'when the url is on a host outside the LMS domains' do
      let(:url) { 'https://169.254.169.254/latest/meta-data' }

      it_behaves_like 'a url outside the LMS'
    end

    context 'when the url uses another scheme' do
      let(:url) { 'http://test.host/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'a url outside the LMS'
    end

    context 'when the url uses another port' do
      let(:url) { 'https://test.host:6379/' }

      it_behaves_like 'a url outside the LMS'
    end

    context 'when the LMS host has left the LMS domains' do
      let(:client_host) { 'https://old-lms.example.edu' }
      let(:url) { 'https://old-lms.example.edu/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'a url outside the LMS'
    end

    context 'when the LMS host has no scheme' do
      let(:client_host) { 'test.host' }
      let(:url) { 'https://test.host/api/lti/courses/1/names_and_roles' }

      it_behaves_like 'a url outside the LMS'
    end
  end
end
