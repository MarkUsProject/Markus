describe CoursesController do
  let(:admin) { create :admin }
  let(:course) { create :course }

  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(admin)
  end

  context 'accessing course pages' do
    it 'responds with success on index' do
      get :index
      expect(response.status).to eq(200)
    end
    # TODO: enable this once we have a show action.
    xit 'responds with success on show' do
      get :show, params: { id: course }
      expect(response.status).to eq(200)
    end
  end
end
