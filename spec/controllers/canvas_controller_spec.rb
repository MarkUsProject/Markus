describe CanvasController do
  let(:instructor) { create :instructor }
  describe '#get_config', :get_config do
    it 'should respond with success when not logged in' do
      get :get_config
      expect(response.status).to eq(200)
    end
    it 'should respond with success when logged in' do
      get_as instructor, :get_config
      expect(response.status).to eq(200)
    end
  end
  include_examples 'lti deployment controller'
end
