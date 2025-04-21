describe CanvasController do
  let(:instructor) { create(:instructor) }

  describe '#get_config', get_config: true do
    it 'should respond with success when not logged in' do
      get :get_config
      expect(response).to have_http_status(:ok)
    end

    it 'should respond with success when logged in' do
      get_as instructor, :get_config
      expect(response).to have_http_status(:ok)
    end
  end

  it_behaves_like 'lti deployment controller'
end
