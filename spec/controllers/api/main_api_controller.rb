describe Api::MainApiController do
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create

      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :create, params: { id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: 1 }
      expect(response.status).to eq(403)
    end
  end
  context 'An authenticated request' do
    before :each do
      admin = create :admin
      admin.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
    end
    it 'should return a 404 error for a generic GET index request' do
      get :index
      expect(response.status).to eq(404)
    end

    it 'should return a 404 error for a generic GET show request' do
      get :show, params: { id: 1 }
      expect(response.status).to eq(404)
    end

    it 'should return a 404 error for a generic POST create request' do
      post :create

      expect(response.status).to eq(404)
    end

    it 'should return a 404 error for a generic PUT update request' do
      put :create, params: { id: 1 }
      expect(response.status).to eq(404)
    end

    it 'should return a 404 error for a generic DELETE destroy request' do
      delete :destroy, params: { id: 1 }
      expect(response.status).to eq(404)
    end
  end
end
