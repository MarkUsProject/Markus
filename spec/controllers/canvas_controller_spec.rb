describe CanvasController do
  let(:instructor) { create :instructor }
  describe '#get_config', :get_config do
    it 'should respond with success when not logged in' do
      is_expected.to respond_with(:success)
    end
    before { get_as instructor, :get_canvas_config }
    it 'should respond with success when logged in' do
      is_expected.to respond_with(:success)
    end
  end
  describe '#check_host' do
    it 'does not redirect to an error with a known host' do
      get_as instructor, :get_canvas_config
      is_expected.to respond_with(:success)
    end
    it 'does redirect to an error with an unknown host' do
      @request.host = 'example.com'
      get_as instructor, :get_canvas_config
      expect(response).to render_template('shared/http_status')
    end
  end
end
