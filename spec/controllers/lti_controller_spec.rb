describe LtiController do
  let(:instructor) { create :instructor }
  describe 'get_config', :get_canvas_config do
    it 'should respond with success when not logged in' do
      is_expected.to respond_with(:success)
    end
    before { get_as instructor, :get_canvas_config }
    it 'should respond with success when logged in' do
      is_expected.to respond_with(:success)
    end
  end
end
