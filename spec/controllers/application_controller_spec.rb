describe ApplicationController do
  render_views

  controller do
    # The route has no course, so the user has no role and every rule denies.
    def index
      authorize! to: :show?
    end

    def implicit_authorization_target
      Course.new
    end
  end

  let(:user) { create(:instructor).user }

  before { sign_in user }

  describe 'a denied request' do
    it 'renders the HTML error page for HTML' do
      get :index
      expect(response).to have_http_status(:forbidden)
      expect(response.media_type).to eq 'text/html'
    end

    it 'renders the HTML error page for any media type' do
      request.accept = '*/*'
      get :index
      expect(response).to have_http_status(:forbidden)
      expect(response.media_type).to eq 'text/html'
    end

    it 'renders JSON for a .json request' do
      get :index, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.media_type).to eq 'application/json'
      expect(response.parsed_body['code']).to eq '403'
    end

    it 'renders JSON for an Accept: application/json request' do
      request.accept = 'application/json'
      get :index
      expect(response).to have_http_status(:forbidden)
      expect(response.media_type).to eq 'application/json'
    end

    it 'returns an empty body for other formats' do
      get :index, format: :csv
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
