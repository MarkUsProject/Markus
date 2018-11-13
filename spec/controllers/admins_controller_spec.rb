describe AdminsController do

  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context 'An Admin should' do
    it 'be able to get :new' do
      get :new
      expect(response.status).to eq(200)
    end

    it 'respond with success on index' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'be able to create Admin' do
      post :create, params: { user: { user_name: 'jdoe', last_name: 'Doe', first_name: 'Jane' } }
      Admin.find_by_user_name('jdoe')
      expect(response).to redirect_to action: 'index'
    end

    context 'with a second user' do
      before do
        @a2 = Admin.create(user_name: 'admin2',
                         last_name: 'admin2',
                         first_name: 'admin2')
      end

      it 'be able to update' do
        put :update, params: { id: @a2.id, user: { last_name: 'John', first_name: 'Doe' } }
        expect(response).to redirect_to action: 'index'
      end

      it 'be able to edit' do
        get :edit, params: { id: @a2.id }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to be_truthy
      end
    end
  end

end
